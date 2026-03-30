const messages = [];

export function showMessage(type, text) {
  const message = {
    type,
    text,
    timestamp: new Date().toLocaleTimeString()
  };
  
  messages.push(message);
  updateMessagesDisplay();
}

export function updateMessagesDisplay() {
  const messageContainer = document.getElementById('messages-content');
  if (!messageContainer) return;
  
  messageContainer.innerHTML = messages.map(msg => 
    `<div>${msg.timestamp} - ${msg.text}</div>`
  ).join('');
}

export async function checkDevMode() {
  try {
    const response = await fetch('/api/dev-mode');
    const data = await response.json();
    if (data.isDevMode) {
      showMessage('info', '🔧 Dev Mode');
    }
  } catch (error) {
    console.error('Failed to check dev mode status:', error);
    showMessage('warning', 'Could not determine dev mode status.');
  }
}
