// scripts/refresh-cogs.js
// Load environment variables from repo root
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const { Storage } = require('@google-cloud/storage');
const fs = require('fs').promises;
const path = require('path');

// --- Configuration from environment ---
const BUCKET_NAME = process.env.BUCKET_NAME || 'deeptime-cogs-deeptime-491316';
const TITILER_URL = process.env.TITILER_URL || 'https://titiler-5mk5kd2qna-uc.a.run.app';
const OUTPUT_FILE = path.join(__dirname, '../browse-server/public/cogs.json');

console.log(`📋 Config: Bucket=${BUCKET_NAME}, TiTiler=${TITILER_URL}`);
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

    // 2. Fetch metadata for each file from TiTiler
    const cogDataPromises = cogFiles.map(async (file) => {
      const gcsUrl = `gs://${BUCKET_NAME}/${file.name}`;
      const encodedUrl = encodeURIComponent(gcsUrl);
      const infoUrl = `${TITILER_URL}/cog/info?url=${encodedUrl}`;

      console.log(`Fetching metadata for: ${file.name}`);
      try {
        const response = await fetch(infoUrl);
        if (!response.ok) {
          console.warn(`-  WARN: Failed to fetch metadata for ${file.name}. Status: ${response.status}. Skipping.`);
          return null;
        }
        const info = await response.json();

        // 3. Assemble the configuration object
        return {
          url: gcsUrl,
          name: info.metadata?.SITE_NAME || file.name, // Fallback to filename
          bounds: info.bounds,
          minzoom: info.minzoom,
          maxzoom: info.maxzoom,
          type: info.metadata?.GEOREF_TYPE || 'unknown',
        };
      } catch (error) {
        console.error(`-  ERROR: Could not process ${file.name}.`, error);
        return null;
      }
    });

    const allCogData = (await Promise.all(cogDataPromises)).filter(Boolean); // Filter out nulls from failed requests

    // 4. Write the configuration to the output file
    await fs.writeFile(OUTPUT_FILE, JSON.stringify(allCogData, null, 2));
    console.log(`\n✅ Successfully wrote configuration for ${allCogData.length} COGs to ${OUTPUT_FILE}`);

  } catch (error) {
    console.error('\n❌ An unexpected error occurred during the refresh process:', error);
    process.exit(1);
  }
}

refreshCogs();
