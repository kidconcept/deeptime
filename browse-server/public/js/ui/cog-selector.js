export function populateCogSelector(cogDetails) {
  const selector = document.getElementById('cog-selector-dropdown');
  selector.innerHTML = '';

  cogDetails.forEach(cog => {
    const option = document.createElement('option');
    option.value = cog.url;
    option.textContent = cog.name;
    selector.appendChild(option);
  });

  selector.addEventListener('change', (e) => {
    if (e.target.value) {
      const event = new CustomEvent('cogChanged', {
        detail: { url: e.target.value }
      });
      document.dispatchEvent(event);
    }
  });
}
