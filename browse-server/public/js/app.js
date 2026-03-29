import { initializeMap, updateTileLayer, fitBounds } from './map-controller.js';
import { fetchAllCogMetadata, getCogInfo } from './cog-data-manager.js';
import { populateCogSelector } from './ui/cog-selector.js';
import { displayMetadata } from './ui/metadata-panel.js';
import { showMessage, checkDevMode } from './ui/message-bus.js';

const state = {
  cogData: [],
  currentCogUrl: null,
  map: null,
};

document.addEventListener('DOMContentLoaded', async () => {
  showMessage('info', 'Initializing viewer...', { timeout: 2000 });
  
  state.map = initializeMap();
  
  await checkDevMode();

  state.cogData = await fetchAllCogMetadata();
  
  populateCogSelector(state.cogData);

  // Set default COG
  const defaultCog = state.cogData.find(c => c.url.includes('georef'));
  if (defaultCog) {
    state.currentCogUrl = defaultCog.url;
    loadCog(state.currentCogUrl);
  }

  document.addEventListener('cogChanged', (e) => {
    state.currentCogUrl = e.detail.url;
    loadCog(state.currentCogUrl);
  });
});

async function loadCog(url) {
  showMessage('info', `Loading COG: ${url.split('/').pop()}`);
  try {
    const cogInfo = await getCogInfo(url);
    
    if (!cogInfo || !cogInfo.bounds) {
      throw new Error('Failed to get valid COG info.');
    }

    updateTileLayer(state.map, url, cogInfo);
    fitBounds(state.map, cogInfo.bounds);
    displayMetadata(cogInfo);
    
    showMessage('info', 'COG loaded successfully.', { timeout: 3000 });
  } catch (error) {
    console.error('Error loading COG:', error);
    showMessage('error', `Error loading COG: ${error.message}`);
  }
}
