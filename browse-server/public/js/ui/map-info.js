export function displayMapInfo(cogData) {
  const container = document.getElementById('map-info-content');
  if (!cogData) {
    container.innerHTML = '<p>No map info available.</p>';
    return;
  }

  const { name, bounds, minzoom, maxzoom } = cogData;

  container.innerHTML = `
    <p><strong>Site Name:</strong> ${name}</p>
    <p><strong>Zoom (Min/Max):</strong> ${minzoom} / ${maxzoom}</p>
    <p><strong>Bounds:</strong> ${bounds.join(', ')}</p>
  `;
}
