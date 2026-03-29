export function displayMetadata(cogData) {
  const container = document.getElementById('metadata-container');
  if (!cogData) {
    container.innerHTML = '<p>No metadata available.</p>';
    return;
  }

  const { name, bounds, minzoom, maxzoom } = cogData;

  container.innerHTML = `
    <h3>Metadata</h3>
    <p><strong>Site Name:</strong> ${name}</p>
    <p><strong>Zoom (Min/Max):</strong> ${minzoom} / ${maxzoom}</p>
    <p><strong>Bounds:</strong> ${bounds.join(', ')}</p>
  `;
}
