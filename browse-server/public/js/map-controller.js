let map;
let isFirstLoad = true; // Track first load to delay satellite layer

// Zoom configuration - all zoom levels managed here for consistency
const ZOOM_CONFIG = {
  MIN_ZOOM: 3,              // Minimum zoom: see multiple continents (Brazil + NY visible)
  MAX_ZOOM: 28,             // Maximum zoom: extreme detail for coral inspection
  DEFAULT_ZOOM: 2,          // Initial zoom level
  SATELLITE_MAX_NATIVE: 18  // Esri satellite tiles available up to zoom 18
};

// Initialize empty map without any tile layers
// Satellite layer will be added after first COG tiles are ready
export function initializeMap() {
  map = L.map('map', {
    minZoom: ZOOM_CONFIG.MIN_ZOOM,
    maxZoom: ZOOM_CONFIG.MAX_ZOOM,
    zoomControl: true
  }).setView([0, 0], ZOOM_CONFIG.DEFAULT_ZOOM);

  return map;
}

// Add satellite basemap layer after COG tiles are ready
// Called after first successful COG tile load to avoid wasting bandwidth during cold start
export function addSatelliteLayer(mapInstance) {
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

  satelliteLayer.addTo(mapInstance);
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
  
  // On first load, listen for first successful tile to trigger satellite layer loading
  // This ensures TiTiler is responsive before loading satellite imagery
  if (isFirstLoad) {
    cogLayer.on('tileload', function onFirstTile() {
      // Dispatch event to signal tiles are ready
      document.dispatchEvent(new CustomEvent('cogTilesReady'));
      
      // Remove this listener - only needed for first tile
      cogLayer.off('tileload', onFirstTile);
      
      isFirstLoad = false;
    });
  }
  
  // Add COG layer to map (starts tile loading)
  cogLayer.addTo(mapInstance);
}

export function fitBounds(mapInstance, bounds) {
  if (bounds && bounds.length === 4) {
    const [minX, minY, maxX, maxY] = bounds;
    mapInstance.fitBounds([[minY, minX], [maxY, maxX]]);
  }
}
