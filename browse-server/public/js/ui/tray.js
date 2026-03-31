const MOBILE_BREAKPOINT = 768;

export function initTray() {
  const btn = document.getElementById('tray-toggle-btn');
  if (!btn) return;

  const isMobile = () => window.innerWidth <= MOBILE_BREAKPOINT;

  // Set initial state: closed on mobile, open on desktop
  if (isMobile()) {
    close();
  } else {
    open();
  }

  btn.addEventListener('click', () => {
    if (document.body.classList.contains('tray-closed')) {
      open();
    } else {
      close();
    }
  });
}

function open() {
  document.body.classList.remove('tray-closed');
  const btn = document.getElementById('tray-toggle-btn');
  if (btn) btn.setAttribute('aria-expanded', 'true');
}

function close() {
  document.body.classList.add('tray-closed');
  const btn = document.getElementById('tray-toggle-btn');
  if (btn) btn.setAttribute('aria-expanded', 'false');
}
