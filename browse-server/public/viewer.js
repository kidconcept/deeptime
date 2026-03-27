// DeepTime COG Viewer Configuration
// Connects to TiTiler for serving Cloud Optimized GeoTIFFs

// Configuration - Use local proxy to avoid CORS issues
const TITILER_URL = '/api/titiler';
const DEFAULT_COG = 'gs://deeptime-cogs-deeptime-491316/18palms.tif';

// Available COG files - update this list with your COGs
const COG_FILES = [
  { name: '18th Palm North', url: 'gs://deeptime-cogs-deeptime-491316/18palms.tif' },
  // Add more COGs here as they become available
  // { name: 'Site Name', url: 'gs://bucket/file.tif' },
];

// Initialize map
let map = null;
let currentTileLayer = null;
let currentCOG = null;

// Initialize the map when page loads
console.log('🚀 viewer.js loaded - waiting for DOM...');

function initializeViewer() {
  console.log('✅ DOM ready - initializing viewer...');
  initMap();
  populateCOGSelector();
  
  // Load default COG if available
  if (COG_FILES.length > 0) {
    console.log(`📍 Loading default COG: ${COG_FILES[0].name}`);
    loadCOG(COG_FILES[0].url);
  }
}

// Check if DOM is already ready (in case script loads late)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeViewer);
} else {
  // DOM already loaded
  initializeViewer();
}

// Initialize Leaflet map
function initMap() {
  console.log('🗺️  Initializing Leaflet map...');
  map = L.map('map', {
    center: [0, 0],
    zoom: 2,
    zoomControl: true,
    attributionControl: true
  });

  // Add base layer (dark mode for better contrast with imagery)
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '© OpenStreetMap contributors © CARTO',
    maxZoom: 20
  }).addTo(map);

  // Add scale control
  L.control.scale({ imperial: false, metric: true }).addTo(map);

  // Add click handler for coordinates
  map.on('click', (e) => {
    const lat = e.latlng.lat.toFixed(6);
    const lng = e.latlng.lng.toFixed(6);
    document.getElementById('coordinates').textContent = `📍 ${lat}, ${lng}`;
    
    // Optional: Add a temporary marker
    const marker = L.marker(e.latlng).addTo(map);
    setTimeout(() => marker.remove(), 2000);
  });
}

// Populate COG selector dropdown
function populateCOGSelector() {
  const selector = document.getElementById('cog-selector');
  
  COG_FILES.forEach(cog => {
    const option = document.createElement('option');
    option.value = cog.url;
    option.textContent = cog.name;
    selector.appendChild(option);
  });

  // Set default selection
  if (COG_FILES.length > 0) {
    selector.value = COG_FILES[0].url;
  }

  // Add change handler
  selector.addEventListener('change', (e) => {
    if (e.target.value) {
      loadCOG(e.target.value);
    }
  });
}

// Load COG from TiTiler
async function loadCOG(cogUrl) {
  console.log(`📥 loadCOG called with: ${cogUrl}`);
  if (!cogUrl) return;

  showLoading(true);
  currentCOG = cogUrl;

  try {
    // Fetch COG info from TiTiler
    const infoUrl = `${TITILER_URL}/cog/info?url=${encodeURIComponent(cogUrl)}`;
    console.log(`🔍 Fetching COG info from: ${infoUrl}`);
    const response = await fetch(infoUrl);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch COG info: ${response.status}`);
    }

    const info = await response.json();
    console.log('COG Info:', info);
    
    // Check if this is an "unreferenced" COG (arbitrary coordinates)
    const isUnreferenced = info.metadata?.COORDINATE_SYSTEM === 'unreferenced';
    if (isUnreferenced) {
      console.log('ℹ️  COG marked as UNREFERENCED (arbitrary coordinate space)');
      if (info.metadata?.SCALE_M_PER_PX || info.metadata?.UNREFERENCED_SCALE_M_PER_PX) {
        const scale = info.metadata?.SCALE_M_PER_PX || info.metadata?.UNREFERENCED_SCALE_M_PER_PX;
        console.log(`   Scale: ${scale} m/pixel`);
      }
      if (info.metadata?.GEOREF_ANCHOR) {
        console.log(`   Anchor: ${info.metadata.GEOREF_ANCHOR}`);
      }
      if (info.metadata?.NATIVE_ZOOM_LEVEL) {
        console.log(`   Native zoom: ${info.metadata.NATIVE_ZOOM_LEVEL}`);
        console.log(`   Zoom range: ${info.metadata.RECOMMENDED_MIN_ZOOM} to ${info.metadata.RECOMMENDED_MAX_ZOOM}`);
      }
    }
    updateCoordSystemIndicator(isUnreferenced);

    // Fetch COG bounds
    const boundsUrl = `${TITILER_URL}/cog/bounds?url=${encodeURIComponent(cogUrl)}`;
    const boundsResponse = await fetch(boundsUrl);
    
    if (!boundsResponse.ok) {
      throw new Error(`Failed to fetch COG bounds: ${boundsResponse.status}`);
    }

    const boundsData = await boundsResponse.json();
    let bounds = boundsData.bounds;
    console.log('COG Bounds:', bounds);

    // Check if COG has valid georeferencing
    const isValidGeoreferencing = checkValidGeoreferencing(bounds, info);
    
    if (!isValidGeoreferencing) {
      console.warn('COG appears to have arbitrary/invalid georeferencing. Using fallback mode.');
      bounds = calculateFallbackBounds(info);
      console.log('Calculated fallback bounds from pixel dimensions:', bounds);
    }

    // Remove existing tile layer or image overlay
    if (currentTileLayer) {
      map.removeLayer(currentTileLayer);
      currentTileLayer = null;
    }

    // Use tile layer for progressive loading (always, even with calculated bounds)
    console.log(`Using tile mode with ${isValidGeoreferencing ? 'original' : 'calculated'} bounds`);
    
    // Extract zoom parameters from COG metadata (if available)
    const metadata = info.metadata || {};
    const minZoom = parseInt(metadata.RECOMMENDED_MIN_ZOOM) || 0;
    const maxZoom = parseInt(metadata.RECOMMENDED_MAX_ZOOM) || 24;
    const nativeZoom = parseInt(metadata.NATIVE_ZOOM_LEVEL);
    
    if (nativeZoom) {
      console.log(`📏 Using COG metadata zoom levels: ${minZoom}-${maxZoom} (native: ${nativeZoom})`);
    }
    
    const tileUrl = `${TITILER_URL}/cog/tiles/WebMercatorQuad/{z}/{x}/{y}?url=${encodeURIComponent(cogUrl)}`;
    currentTileLayer = L.tileLayer(tileUrl, {
      minZoom: minZoom,
      maxZoom: maxZoom,
      tileSize: 256,
      attribution: 'COG via TiTiler',
      errorTileUrl: '' // Don't show broken tile images
    }).addTo(map);

    // Fit map to COG bounds (either original or calculated)
    const leafletBounds = L.latLngBounds(
      [bounds[1], bounds[0]], // Southwest corner
      [bounds[3], bounds[2]]  // Northeast corner
    );
    
    console.log('Leaflet bounds:', leafletBounds.toBBoxString());
    console.log('Center:', leafletBounds.getCenter());
    
    // Fit bounds with padding, respecting the COG's max zoom level
    map.fitBounds(leafletBounds, { 
      padding: [50, 50],
      maxZoom: maxZoom
    });

    showLoading(false);
    
    const geoStatus = isValidGeoreferencing ? 'Georeferenced' : 'Non-georeferenced (preview mode)';
    const zoomLevel = map.getZoom();
    const center = map.getCenter();
    
    document.getElementById('coordinates').textContent = `✅ ${geoStatus} - Click map for coordinates`;
    
    console.log(`COG loaded successfully. Zoom: ${zoomLevel}, Center: [${center.lat.toFixed(4)}, ${center.lng.toFixed(4)}]`);

  } catch (error) {
    console.error('Error loading COG:', error);
    showLoading(false);
    alert(`Error loading COG: ${error.message}\n\nPlease check:\n- TiTiler service is running\n- COG file exists in GCS\n- COG URL is correct`);
  }
}

// Check if COG has valid georeferencing
function checkValidGeoreferencing(bounds, info) {
  // Check for obviously invalid bounds
  const [minX, minY, maxX, maxY] = bounds;
  
  // Calculate extent
  const width = maxX - minX;
  const height = maxY - minY;
  
  // Degenerate bounds (zero width or height = line or point)
  if (width === 0 || height === 0) {
    console.warn('Degenerate bounds detected (zero width or height)');
    return false;
  }
  
  // If bounds span entire or larger than Earth (suspicious)
  if (Math.abs(width) >= 360 || Math.abs(height) >= 180) {
    console.warn('Bounds span entire Earth or larger (likely arbitrary)');
    return false; 
  }
  
  // If bounds are suspiciously large (pixel coordinates)
  if (Math.abs(width) > 100000 || Math.abs(height) > 100000) {
    console.warn('Bounds are extremely large (likely pixel coordinates)');
    return false;
  }
  
  // Check if bounds are all zeros
  if (minX === 0 && minY === 0 && maxX === 0 && maxY === 0) {
    console.warn('All bounds are zero');
    return false;
  }
  
  console.log('Bounds appear to be valid georeferencing');
  return true;
}

// Calculate fallback bounds for non-georeferenced COGs
function calculateFallbackBounds(info) {
  // Get image dimensions from COG info
  const width = info.width || 1024;
  const height = info.height || 1024;
  
  // For non-georeferenced images, create a visible extent
  // Use a scale that makes the image clearly visible on the map
  // Target: Make the image span a reasonable area (like a few degrees)
  const targetWidthDegrees = 2.0; // Make image ~2 degrees wide for visibility
  const aspectRatio = height / width;
  const targetHeightDegrees = targetWidthDegrees * aspectRatio;
  
  // Center at 0,0 (equator, prime meridian)
  const centerLat = 0;
  const centerLng = 0;
  
  // Create bounds centered at 0,0
  const bounds = [
    centerLng - targetWidthDegrees / 2,  // minX
    centerLat - targetHeightDegrees / 2, // minY
    centerLng + targetWidthDegrees / 2,  // maxX
    centerLat + targetHeightDegrees / 2  // maxY
  ];
  
  console.log(`Image dimensions: ${width} x ${height} pixels`);
  console.log(`Aspect ratio: ${aspectRatio.toFixed(3)}`);
  console.log(`Calculated extent: ${targetWidthDegrees.toFixed(4)}° × ${targetHeightDegrees.toFixed(4)}°`);
  console.log(`Bounds: [${bounds.map(b => b.toFixed(4)).join(', ')}]`);
  
  return bounds;
}

// Show/hide loading indicator
function showLoading(show) {
  const indicator = document.getElementById('loading-indicator');
  if (show) {
    indicator.classList.remove('hidden');
  } else {
    indicator.classList.add('hidden');
  }
}

// Update coordinate system indicator
function updateCoordSystemIndicator(isUnreferenced) {
  const indicator = document.getElementById('coord-system-indicator');
  if (isUnreferenced) {
    indicator.textContent = 'Unreferenced Coordinate System';
    indicator.className = 'coord-system unreferenced';
  } else {
    indicator.textContent = 'Georeferenced (Lat/Lon)';
    indicator.className = 'coord-system referenced';
  }
}
