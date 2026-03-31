# Browse Server Tools

Tools are interactive map modes. Only one tool can be active at a time — the Tool Manager enforces this automatically.

---

## Architecture

- **`tool-manager.js`** — central registry, enforces single-active-tool
- **`tools/*.js`** — one file per tool
- **`app.js`** — initializes each tool after the map is created

## Current Tools

| Tool | File | Purpose |
|------|------|---------|
| Coordinates | `coordinates-tool.js` | Click map to show lat/lon |
| Measure | `measure-tool.js` | Click two points to measure distance |

---

## Creating a New Tool

### 1. Create `js/tools/your-tool.js`

```javascript
import { registerTool, isToolActive, activateTool, deactivateTool } from '../ui/tool-manager.js';

const TOOL_ID = 'your-tool';
let map = null;
let eventListeners = {};

export function init(mapInstance) {
  map = mapInstance;
  registerTool(TOOL_ID, activate, deactivate);

  const button = document.getElementById('your-tool-btn');
  const toggleTool = () => {
    if (isToolActive(TOOL_ID)) {
      deactivateTool(TOOL_ID);
    } else {
      activateTool(TOOL_ID);
    }
  };

  button.addEventListener('click', toggleTool);

  const label = button.parentElement.querySelector('.tool-label');
  if (label) {
    label.addEventListener('click', toggleTool);
  }
}

function activate() {
  document.getElementById('your-tool-btn').classList.add('active');
  map.getContainer().classList.add('your-tool-active');

  eventListeners.click = (e) => {
    // handle map click
  };
  map.on('click', eventListeners.click);
}

function deactivate() {
  document.getElementById('your-tool-btn').classList.remove('active');
  map.getContainer().classList.remove('your-tool-active');

  if (eventListeners.click) {
    map.off('click', eventListeners.click);
    eventListeners.click = null;
  }
}```

### 2. Add button to index.html (#tools section)

Icons are rendered via a CSS class on the button — the button element itself has no inner content. Add a CSS class (e.g. `your-tool-icon`) and define it in `styles.css`.

```html
<div class="tool-item">
  <button id="your-tool-btn" class="tool-icon-button your-tool-icon" title="Your Tool">
  </button>
  <label class="tool-label">Your Tool</label>
</div>
```

### 3. Add cursor style to styles.css

```css
.your-tool-active,
.your-tool-active * {
  cursor: crosshair !important;
}
```

### 4. Register in app.js

```javascript
import { init as initYourTool } from './tools/your-tool.js';
```

Inside the `DOMContentLoaded` async callback, after `state.map = initializeMap()`:

```javascript
initYourTool(state.map);
```