import { initializeMap, updateTileLayer, fitBounds, addSatelliteLayer } from './map-controller.js';
import { fetchCogConfig } from './cog-data-manager.js';
import { populateCogSelector } from './ui/cog-selector.js';
import { displayMapInfo } from './ui/map-info.js';
import { showMessage, checkDevMode } from './ui/message-bus.js';
import { init as initCoordinatesTool } from './tools/coordinates-tool.js';
import { init as initMeasureTool } from './tools/measure-tool.js';
import { initTray } from './ui/tray.js';

const state = {
  cogConfig: [],
  currentCogUrl: null,
  map: null,
};

document.addEventListener('DOMContentLoaded', async () => {
  showMessage('info', 'Initializing viewer...');
  
  // Initialize empty map (no layers yet)
  state.map = initializeMap();

  // Initialize tray toggle
  initTray();

  // Initialize tools
  initCoordinatesTool(state.map);
  initMeasureTool(state.map);
  
  await checkDevMode();

  state.cogConfig = await fetchCogConfig();
  
  if (state.cogConfig.length === 0) {
    showMessage('error', 'COG configuration is empty. Please run "npm run refresh-cogs".');
    return;
  }

  populateCogSelector(state.cogConfig);

  // Set default COG to the first one in the list
  state.currentCogUrl = state.cogConfig[0].url;

  // Start cold-start monitoring before loading
  const stopMonitoring = startLoadMonitoring();

  // Listen for first successful tile load (once only)
  document.addEventListener('cogTilesReady', () => {
    stopMonitoring();
    // Add satellite layer after COG tiles are ready
    addSatelliteLayer(state.map);
    showMessage('info', 'Tiles streaming — zoom and pan to explore');
    document.getElementById('loading-overlay').classList.add('hidden');
  }, { once: true });

  loadCog(state.currentCogUrl);

  document.addEventListener('cogChanged', (e) => {
    state.currentCogUrl = e.detail.url;
    document.getElementById('loading-overlay').classList.remove('hidden');
    loadCog(state.currentCogUrl);
  });
});

function startLoadMonitoring() {
  let done = false;

  const t10 = setTimeout(() => {
    if (!done) showMessage('info', 'Tile server may be cold-starting...');
  }, 10000);

  const t30 = setTimeout(() => {
    if (!done) showMessage('info', 'Still warming up — cold starts can take 1-2 minutes');
  }, 30000);

  const t45 = setTimeout(() => {
    if (!done) showMessage('info', 'Thanks for your patience, almost there...');
  }, 45000);

  fetch('/api/titiler/healthz')
    .then(res => {
      if (!done) {
        clearTimeout(t30);
        clearTimeout(t45);
        showMessage('info', 'Tile server is ready. Reading image data from cloud storage...');
      }
    })
    .catch(() => {
      // healthz failure is non-fatal — tile loading may still succeed
    });

  return function stop() {
    done = true;
    clearTimeout(t10);
    clearTimeout(t30);
    clearTimeout(t45);
  };
}

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
    displayMapInfo(cogData);
  } catch (error) {
    console.error('Error loading COG:', error);
    showMessage('error', `Error loading COG: ${error.message}`);
  }
}
