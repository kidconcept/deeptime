// scripts/refresh-cogs.js
// Load environment variables from repo root
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const { Storage } = require('@google-cloud/storage');
const fs = require('fs');
const fsPromises = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// --- Configuration from environment ---
const BUCKET_NAME = process.env.BUCKET_NAME || 'deeptime-cogs-deeptime-491316';
const TITILER_URL = process.env.TITILER_URL || 'https://titiler-5mk5kd2qna-uc.a.run.app';
const OUTPUT_FILE = path.join(__dirname, '../browse-server/public/cogs.json');
const PROJECT_ROOT = path.join(__dirname, '..');
const CREDS_FILE = path.join(PROJECT_ROOT, 'keys/titiler-sa-key.json');

console.log(`📋 Config: Bucket=${BUCKET_NAME}, TiTiler=${TITILER_URL}`);

// Set GDAL credentials for reading from GCS
if (fs.existsSync(CREDS_FILE)) {
  process.env.GOOGLE_APPLICATION_CREDENTIALS = CREDS_FILE;
}
// ---

async function refreshCogs() {
  // Dynamically import node-fetch
  const fetch = (await import('node-fetch')).default;

  console.log('🚀 Starting COG configuration refresh...');

  try {
    // 1. List files in GCS Bucket
    console.log(`Listing files in bucket: ${BUCKET_NAME}`);
    const storage = new Storage();
    const [files] = await storage.bucket(BUCKET_NAME).getFiles();
    const cogFiles = files.filter(file => file.name.endsWith('.tif'));
    console.log(`Found ${cogFiles.length} COG files.`);

    // 2. Fetch metadata for each file
    const cogDataPromises = cogFiles.map(async (file) => {
      const gcsUrl = `gs://${BUCKET_NAME}/${file.name}`;

      console.log(`Fetching metadata for: ${file.name}`);
      try {
        // Read GDAL metadata directly from GCS file
        const gdalinfoOutput = execSync(`gdalinfo /vsigs/${BUCKET_NAME}/${file.name}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
        
        // Extract custom metadata (SITE_NAME, GEOREF_TYPE) from GDAL output
        let siteName = file.name;
        let geoRefType = 'unknown';
        
        const siteNameMatch = gdalinfoOutput.match(/SITE_NAME=(.*?)(?:\n|$)/);
        if (siteNameMatch) {
          siteName = siteNameMatch[1].trim();
        }
        
        const geoRefMatch = gdalinfoOutput.match(/GEOREF_TYPE=(.*?)(?:\n|$)/);
        if (geoRefMatch) {
          geoRefType = geoRefMatch[1].trim();
        }

        // Still fetch TiTiler for bounds and zoom levels
        const encodedUrl = encodeURIComponent(gcsUrl);
        const infoUrl = `${TITILER_URL}/cog/info?url=${encodedUrl}`;

        const response = await fetch(infoUrl);
        if (!response.ok) {
          console.warn(`-  WARN: Failed to fetch TiTiler metadata for ${file.name}. Status: ${response.status}. Skipping.`);
          return null;
        }
        const info = await response.json();

        // 3. Assemble the configuration object with GDAL metadata + TiTiler bounds/zoom
        return {
          url: gcsUrl,
          name: siteName,
          bounds: info.bounds,
          minzoom: info.minzoom,
          maxzoom: info.maxzoom,
          type: geoRefType,
        };
      } catch (error) {
        console.error(`-  ERROR: Could not process ${file.name}.`, error.message);
        return null;
      }
    });

    const allCogData = (await Promise.all(cogDataPromises)).filter(Boolean); // Filter out nulls from failed requests

    // 4. Write the configuration to the output file
    await fsPromises.writeFile(OUTPUT_FILE, JSON.stringify(allCogData, null, 2));
    console.log(`\n✅ Successfully wrote configuration for ${allCogData.length} COGs to ${OUTPUT_FILE}`);

  } catch (error) {
    console.error('\n❌ An unexpected error occurred during the refresh process:', error);
    process.exit(1);
  }
}

refreshCogs();
