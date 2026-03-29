export function displayMetadata(info) {
  const container = document.getElementById('metadata-container');
  if (!info) {
    container.innerHTML = '<p>No metadata available.</p>';
    return;
  }

  const { bounds, minzoom, maxzoom, metadata } = info;
  const siteName = metadata?.SITE_NAME || 'N/A';

  container.innerHTML = `
    <h3>Metadata</h3>
    <p><strong>Site Name:</strong> ${siteName}</p>
    <p><strong>Zoom (Min/Max):</strong> ${minzoom} / ${maxzoom}</p>
    <p><strong>Bounds:</strong> ${bounds.join(', ')}</p>
  `;
}
