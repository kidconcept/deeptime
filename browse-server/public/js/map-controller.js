let map;

// Zoom configuration - all zoom levels managed here for consistency
const ZOOM_CONFIG = {
  MIN_ZOOM: 3,              // Minimum zoom: see multiple continents (Brazil + NY visible)
  MAX_ZOOM: 28,             // Maximum zoom: extreme detail for coral inspection
  DEFAULT_ZOOM: 2,          // Initial zoom level
  SATELLITE_MAX_NATIVE: 18  // Esri satellite tiles available up to zoom 18
};

export function initializeMap() {
  map = L.map('map', {
    minZoom: ZOOM_CONFIG.MIN_ZOOM,
    maxZoom: ZOOM_CONFIG.MAX_ZOOM,
    zoomControl: true
  }).setView([0, 0], ZOOM_CONFIG.DEFAULT_ZOOM);

  // Using ESRI World Imagery via local proxy to avoid CORS issues
  // Tiles beyond maxNativeZoom will be scaled up automatically by Leaflet
  const satelliteLayer = L.tileLayer('/api/satellite/{z}/{y}/{x}', {
    attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
    id: 'basemap',
    zIndex: 0,
    minZoom: ZOOM_CONFIG.MIN_ZOOM,
    maxZoom: ZOOM_CONFIG.MAX_ZOOM,  // Allow satellite to display at all zoom levels
    maxNativeZoom: ZOOM_CONFIG.SATELLITE_MAX_NATIVE,  // But only fetch tiles up to zoom 18
    errorTileUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='  // Transparent 1x1 pixel for failed tiles
  });

  satelliteLayer.on('tileerror', function(error, tile) {
    // Silently handle tile errors - expected at high zoom levels
    console.log('Satellite tile unavailable at zoom', tile.coords.z, '(expected beyond', ZOOM_CONFIG.SATELLITE_MAX_NATIVE, ')');
  });

  satelliteLayer.addTo(map);

  return map;
}

export function updateTileLayer(mapInstance, cogData) {
  // Remove previous tile layers (keep basemap)
  mapInstance.eachLayer(layer => {
    if (layer instanceof L.TileLayer && layer.options.id !== 'basemap') {
      mapInstance.removeLayer(layer);
    }
  });

  const tileUrl = `http://localhost:8081/api/titiler/cog/tiles/{z}/{x}/{y}?url=${encodeURIComponent(cogData.url)}`;
  
  // Allow COG to be visible at all map zoom levels
  // TiTiler will serve tiles at any zoom, scaling as needed
  // Bounds restrict where tiles appear geographically
  const cogLayer = L.tileLayer(tileUrl, {
    minZoom: ZOOM_CONFIG.MIN_ZOOM,
    maxZoom: ZOOM_CONFIG.MAX_ZOOM,
    zIndex: 1000,  // Ensure COG renders above satellite
    bounds: cogData.bounds ? [[cogData.bounds[1], cogData.bounds[0]], [cogData.bounds[3], cogData.bounds[2]]] : null
  });
  
  cogLayer.on('tileerror', function(error, tile) {
    // Log COG tile errors for debugging (404s outside bounds are normal)
    if (!error.message || !error.message.includes('404')) {
      console.warn('COG tile error:', error, 'at', tile.coords);
    }
  });
  
  cogLayer.addTo(mapInstance);
}

export function fitBounds(mapInstance, bounds) {
  if (bounds && bounds.length === 4) {
    const [minX, minY, maxX, maxY] = bounds;
    mapInstance.fitBounds([[minY, minX], [maxY, maxX]]);
  }
}
