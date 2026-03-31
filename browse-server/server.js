// Load environment variables from repo root
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const express = require('express');
const path = require('path');

const app = express();
const PORT = 8081;
const DEV_MODE = process.env.NODE_ENV !== 'production';

// Disable all caching mechanisms in dev mode
if (DEV_MODE) {
  app.set('etag', false);
  app.set('x-powered-by', false);
}

// TiTiler configuration from environment
const TITILER_URL = process.env.TITILER_URL || 'https://titiler-5mk5kd2qna-uc.a.run.app';

if (DEV_MODE) {
  console.log(`🔧 DEV MODE: TiTiler URL: ${TITILER_URL}`);
}

// Dev mode: aggressively disable ALL caching
if (DEV_MODE) {
  app.use((req, res, next) => {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');
    res.removeHeader('ETag');
    res.removeHeader('Last-Modified');
    next();
  });
}

// Serve static files from the public directory
// In production: ETags + Last-Modified enabled for conditional GETs (304s save bandwidth).
// maxAge:0 is intentional without cache-busted filenames — browser revalidates but won't re-download unchanged files.
app.use(express.static(path.join(__dirname, 'public'), DEV_MODE ? {
  etag: false,
  lastModified: false,
  maxAge: 0,
  immutable: false,
  cacheControl: false
} : {
  etag: true,
  lastModified: true,
  maxAge: 0
}));

// Proxy endpoint for TiTiler to avoid CORS issues
app.get('/api/titiler/*', async (req, res) => {
  try {
    const titilerPath = req.params[0];
    // Use express's parsed query object which handles decoding
    const params = new URLSearchParams(req.query);
    const queryString = params.toString();
    const url = `${TITILER_URL}/${titilerPath}?${queryString}`;
    
    console.log(`Proxying TiTiler request: ${url}`);
    
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(url, DEV_MODE ? {
      headers: { 'Cache-Control': 'no-cache' }
    } : {});
    
    if (!response.ok) {
      const errorBody = await response.text();
      console.error(`TiTiler returned ${response.status}: ${errorBody}`);
      throw new Error(`TiTiler returned ${response.status}`);
    }
    
    const contentType = response.headers.get('content-type');
    res.setHeader('Content-Type', contentType);
    
    if (contentType && contentType.includes('application/json')) {
      if (!DEV_MODE) res.setHeader('Cache-Control', 'public, max-age=300'); // metadata: 5 min
      const data = await response.json();
      res.json(data);
    } else {
      if (!DEV_MODE) res.setHeader('Cache-Control', 'public, max-age=3600'); // image tiles: 1 hour
      const buffer = await response.arrayBuffer();
      res.send(Buffer.from(buffer));
    }
  } catch (error) {
    console.error('TiTiler proxy error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Proxy endpoint for Esri satellite tiles to avoid CORS issues
app.get('/api/satellite/:z/:y/:x', async (req, res) => {
  try {
    let { z, y, x } = req.params;
    z = parseInt(z);
    
    // Cap satellite tiles at zoom 18 - beyond that, let Leaflet scale the tiles
    const maxSatelliteZoom = 18;
    if (z > maxSatelliteZoom) {
      console.log(`Satellite tile request at z${z} exceeds max (${maxSatelliteZoom}), returning 404`);
      return res.status(404).send('Tile not available beyond zoom 18');
    }
    
    const url = `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}`;
    
    console.log(`Proxying satellite tile: ${z}/${y}/${x}`);
    
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(url);
    
    if (!response.ok) {
      console.error(`Esri tile returned ${response.status}`);
      throw new Error(`Esri tile returned ${response.status}`);
    }
    
    const contentType = response.headers.get('content-type');
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache satellite tiles for 24 hours
    
    const buffer = await response.arrayBuffer();
    res.send(Buffer.from(buffer));
  } catch (error) {
    console.error('Satellite tile proxy error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Endpoint to expose the current mode to the frontend
app.get('/api/dev-mode', (req, res) => {
  res.json({ isDevMode: DEV_MODE });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'leaflet-viewer' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🗺️  Leaflet viewer running at http://0.0.0.0:${PORT}`);
  console.log(`📁 Serving files from: ${path.join(__dirname, 'public')}`);
  console.log(`🔄 TiTiler proxy: ${TITILER_URL}`);
  if (DEV_MODE) {
    console.log('🔧 DEV MODE: All caching disabled - hard refresh (Cmd+Shift+R) to see changes');
  } else {
    console.log('🚀 PRODUCTION MODE: Caching enabled');
  }
});
