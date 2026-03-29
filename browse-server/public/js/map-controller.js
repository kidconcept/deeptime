let map;

export function initializeMap() {
  map = L.map('map').setView([0, 0], 2);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  return map;
}

export function updateTileLayer(mapInstance, url, cogInfo) {
  // Remove previous tile layers
  mapInstance.eachLayer(layer => {
    if (layer instanceof L.TileLayer && !(layer instanceof L.GridLayer)) {
      mapInstance.removeLayer(layer);
    }
  });

const tileUrl = `/api/titiler/cog/tiles/WebMercatorQuad/{z}/{x}/{y}?url=${encodeURIComponent(url)}`;
  
  // Use more reasonable zoom levels (TiTiler's auto-calculated values can be too restrictive)
  L.tileLayer(tileUrl, {
    minZoom: 0,
    maxZoom: 28,
  }).addTo(mapInstance);
}

export function fitBounds(mapInstance, bounds) {
  if (bounds && bounds.length === 4) {
    const [minX, minY, maxX, maxY] = bounds;
    mapInstance.fitBounds([[minY, minX], [maxY, maxX]]);
  }
}
