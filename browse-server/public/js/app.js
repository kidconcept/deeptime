import { initializeMap, updateTileLayer, fitBounds } from './map-controller.js';
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
  showMessage('info', 'Initializing viewer...', { timeout: 2000 });
  
  state.map = initializeMap();
  
  await checkDevMode();

  state.cogConfig = await fetchCogConfig();
  
  if (state.cogConfig.length === 0) {
    showMessage('error', 'COG configuration is empty. Please run "npm run refresh-cogs".', { persistent: true });
    return;
  }

  populateCogSelector(state.cogConfig);

  // Set default COG to the first one in the list
  state.currentCogUrl = state.cogConfig[0].url;
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
    
    showMessage('info', 'COG loaded successfully.', { timeout: 3000 });
  } catch (error) {
    console.error('Error loading COG:', error);
    showMessage('error', `Error loading COG: ${error.message}`);
  }
}
