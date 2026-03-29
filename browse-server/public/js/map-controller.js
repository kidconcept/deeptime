let map;

export function initializeMap() {
  map = L.map('map').setView([0, 0], 2);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  return map;
}

export function updateTileLayer(mapInstance, cogData) {
  // Remove previous tile layers
  mapInstance.eachLayer(layer => {
    if (layer instanceof L.TileLayer && layer.options.id !== 'basemap') {
      mapInstance.removeLayer(layer);
    }
  });

  const tileUrl = `http://localhost:8081/api/titiler/cog/tiles/{z}/{x}/{y}?url=${encodeURIComponent(cogData.url)}`;
  
  L.tileLayer(tileUrl, {
    minZoom: cogData.minzoom,
    maxZoom: cogData.maxzoom,
  }).addTo(mapInstance);
}

export function fitBounds(mapInstance, bounds) {
  if (bounds && bounds.length === 4) {
    const [minX, minY, maxX, maxY] = bounds;
    mapInstance.fitBounds([[minY, minX], [maxY, maxX]]);
  }
}
