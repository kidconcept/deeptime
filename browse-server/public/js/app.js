import { initializeMap, updateTileLayer, fitBounds, addSatelliteLayer } from './map-controller.js';
import { fetchCogConfig } from './cog-data-manager.js';
import { populateCogSelector } from './ui/cog-selector.js';
import { displayMetadata } from './ui/metadata-panel.js';
import { showMessage, checkDevMode } from './ui/message-bus.js';

const state = {
  cogConfig: [],
  currentCogUrl: null,
  map: null,
};

document.addEventListener('DOMContentLoaded', async () => {
  showMessage('info', 'Initializing viewer...');
  
  // Initialize empty map (no layers yet)
  state.map = initializeMap();
  
  await checkDevMode();

  state.cogConfig = await fetchCogConfig();
  
  if (state.cogConfig.length === 0) {
    showMessage('error', 'COG configuration is empty. Please run "npm run refresh-cogs".');
    return;
  }

  populateCogSelector(state.cogConfig);

  // Set default COG to the first one in the list
  state.currentCogUrl = state.cogConfig[0].url;
  
  // Show waiting message before loading tiles
  showMessage('info', 'Waiting for tiles from server...');
  
  // Listen for first successful tile load (once only)
  document.addEventListener('cogTilesReady', () => {
    // Add satellite layer after COG tiles are ready
    addSatelliteLayer(state.map);
    showMessage('info', 'Tiles loaded successfully.');
  }, { once: true });
  
  loadCog(state.currentCogUrl);

  document.addEventListener('cogChanged', (e) => {
    state.currentCogUrl = e.detail.url;
    loadCog(state.currentCogUrl);
  });
});

function loadCog(url) {
  const cogData = state.cogConfig.find(c => c.url === url);
  
  if (!cogData) {
    showMessage('error', `Could not find configuration for ${url}`);
    return;
  }

  showMessage('info', `Loading COG: ${cogData.name}`);
  try {
    updateTileLayer(state.map, cogData);
    fitBounds(state.map, cogData.bounds);
    displayMetadata(cogData);
  } catch (error) {
    console.error('Error loading COG:', error);
    showMessage('error', `Error loading COG: ${error.message}`);
  }
}
