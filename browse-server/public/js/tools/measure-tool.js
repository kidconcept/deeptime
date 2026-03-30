import { registerTool, isToolActive, activateTool, deactivateTool } from '../ui/tool-manager.js';

const TOOL_ID = 'measure';
let map = null;
let eventListeners = {};

let firstPoint = null;
let secondPoint = null;
let firstMarker = null;
let secondMarker = null;
let measurementLine = null;
let measurementPopup = null;

export function init(mapInstance) {
  map = mapInstance;

  registerTool(TOOL_ID, activate, deactivate);

  const button = document.getElementById('measure-tool-btn');
  const toggleTool = () => {
    if (isToolActive(TOOL_ID)) {
      deactivateTool(TOOL_ID);
    } else {
      activateTool(TOOL_ID);
    }
  };

  button.addEventListener('click', toggleTool);

  const label = button.parentElement.querySelector('.tool-label');
  if (label) {
    label.addEventListener('click', toggleTool);
  }
}

function activate() {
  const button = document.getElementById('measure-tool-btn');
  button.classList.add('active');

  const mapContainer = map.getContainer();
  mapContainer.classList.add('measure-tool-active');

  clearMeasurement();

  eventListeners.click = (e) => {
    handleMapClick(e.latlng);
  };

  map.on('click', eventListeners.click);
}

function deactivate() {
  const button = document.getElementById('measure-tool-btn');
  button.classList.remove('active');

  const mapContainer = map.getContainer();
  mapContainer.classList.remove('measure-tool-active');

  if (eventListeners.click) {
    map.off('click', eventListeners.click);
    eventListeners.click = null;
  }

  clearMeasurement();
}

function handleMapClick(latlng) {
  // Third click behavior: reset previous measurement and start a new one.
  if (firstPoint && secondPoint) {
    clearMeasurement();
  }

  if (!firstPoint) {
    firstPoint = latlng;
    firstMarker = createPointMarker(latlng, '#0b7285');
    return;
  }

  secondPoint = latlng;
  secondMarker = createPointMarker(latlng, '#e8590c');

  const distanceMeters = firstPoint.distanceTo(secondPoint);
  const distanceText = `${distanceMeters.toFixed(2)} m`;

  measurementLine = L.polyline([firstPoint, secondPoint], {
    color: '#0b7285',
    weight: 3,
    opacity: 0.9,
    dashArray: '6, 4'
  }).addTo(map);

  measurementPopup = L.popup({
    closeButton: false,
    autoClose: false,
    className: 'measure-popup'
  })
    .setLatLng(secondPoint)
    .setContent(`Distance: ${distanceText}`)
    .openOn(map);
}

function createPointMarker(latlng, color) {
  return L.circleMarker(latlng, {
    radius: 6,
    color,
    weight: 2,
    fillColor: color,
    fillOpacity: 0.25
  }).addTo(map);
}

function clearMeasurement() {
  firstPoint = null;
  secondPoint = null;

  if (firstMarker) {
    map.removeLayer(firstMarker);
    firstMarker = null;
  }

  if (secondMarker) {
    map.removeLayer(secondMarker);
    secondMarker = null;
  }

  if (measurementLine) {
    map.removeLayer(measurementLine);
    measurementLine = null;
  }

  if (measurementPopup) {
    map.removeLayer(measurementPopup);
    measurementPopup = null;
  }
}