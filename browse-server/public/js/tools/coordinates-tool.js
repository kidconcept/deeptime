import { registerTool, isToolActive, activateTool, deactivateTool } from '../ui/tool-manager.js';

const TOOL_ID = 'coordinates';
let map = null;
let eventListeners = {};
let marker = null;

export function init(mapInstance) {
  map = mapInstance;
  
  // Register tool with tool manager
  registerTool(TOOL_ID, activate, deactivate);
  
  // Set up button and label click handlers
  const button = document.getElementById('coordinates-tool-btn');
  const toggleTool = () => {
    if (isToolActive(TOOL_ID)) {
      deactivateTool(TOOL_ID);
    } else {
      activateTool(TOOL_ID);
    }
  };
  
  button.addEventListener('click', toggleTool);
  
  // Also allow clicking the label to toggle
  const label = button.parentElement.querySelector('.tool-label');
  if (label) {
    label.addEventListener('click', toggleTool);
  }
}

function activate() {
  // Update button state
  const button = document.getElementById('coordinates-tool-btn');
  button.classList.add('active');
  
  // Change cursor to target crosshair
  const mapContainer = map.getContainer();
  mapContainer.classList.add('coordinates-tool-active');
  
  // Add map click listener
  eventListeners.click = (e) => {
    const lat = e.latlng.lat;
    const lng = e.latlng.lng;
    
    // Format with compass directions
    const latDir = lat >= 0 ? 'N' : 'S';
    const lngDir = lng >= 0 ? 'E' : 'W';
    const latFormatted = `${Math.abs(lat).toFixed(6)} ${latDir}`;
    const lngFormatted = `${Math.abs(lng).toFixed(6)} ${lngDir}`;
    
    // Remove existing marker if any
    if (marker) {
      map.removeLayer(marker);
    }
    
    // Create new marker with popup
    marker = L.marker(e.latlng, {
      icon: L.icon({
        iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowSize: [41, 41]
      })
    }).addTo(map);
    
    // Add popup to marker - no close button, no arrow
    marker.bindPopup(`${latFormatted}<br>${lngFormatted}`, {
      closeButton: false,
      className: 'coordinates-popup'
    }).openPopup();
  };
  
  map.on('click', eventListeners.click);
}

function deactivate() {
  // Update button state
  const button = document.getElementById('coordinates-tool-btn');
  button.classList.remove('active');
  
  // Remove target crosshair cursor
  const mapContainer = map.getContainer();
  mapContainer.classList.remove('coordinates-tool-active');
  
  // Remove marker
  if (marker) {
    map.removeLayer(marker);
    marker = null;
  }
  
  // Remove map click listener
  if (eventListeners.click) {
    map.off('click', eventListeners.click);
    eventListeners.click = null;
  }
}
