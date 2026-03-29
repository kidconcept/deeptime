const messageContainer = document.getElementById('message-container');

export function showMessage(type, text, options = {}) {
  const { timeout = 5000, persistent = false } = options;

  const messageEl = document.createElement('div');
  messageEl.className = `message ${type}`;
  messageEl.textContent = text;
  
  messageContainer.appendChild(messageEl);

  if (!persistent) {
    setTimeout(() => {
      messageEl.style.opacity = '0';
      setTimeout(() => messageEl.remove(), 500);
    }, timeout);
  }
}

export async function checkDevMode() {
  try {
    const response = await fetch('/api/dev-mode');
    const data = await response.json();
    if (data.isDevMode) {
      showMessage('info', '🔧 Dev Mode', { persistent: true });
    }
  } catch (error) {
    console.error('Failed to check dev mode status:', error);
    showMessage('warning', 'Could not determine dev mode status.');
  }
}
