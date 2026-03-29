import { updateMessagesDisplay } from './message-bus.js';

export function displayMetadata(info) {
  const container = document.getElementById('metadata-container');
  if (!info) {
    container.innerHTML = '<p>No metadata available.</p><h3>Messages</h3><div id="message-list"></div>';
    updateMessagesDisplay();
    return;
  }

  const { bounds, minzoom, maxzoom, metadata } = info;
  const siteName = metadata?.SITE_NAME || 'N/A';

  container.innerHTML = `
    <h3>Metadata</h3>
    <p><strong>Site Name:</strong> ${siteName}</p>
    <p><strong>TiTiler Zoom:</strong> ${minzoom} / ${maxzoom}</p>
    <p><strong>Viewer Zoom:</strong> 0 / 28</p>
    <p><strong>Bounds:</strong> ${bounds.join(', ')}</p>
    <h3>Messages</h3>
    <div id="message-list"></div>
  `;
  
  updateMessagesDisplay();
}
