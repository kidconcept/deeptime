# Browse Server Tools System

**Documentation for the extensible tool system in the browse-server application**

This guide explains how the tool system works and provides step-by-step instructions for creating new interactive map tools.

---

## Architecture Overview

The tool system uses a **single-active-tool pattern** with three main components:

### 1. Tool Manager (`js/ui/tool-manager.js`)

Central registry that manages tool lifecycle:

```javascript
// Public API
registerTool(toolId, activateFn, deactivateFn)  // Register a new tool
activateTool(toolId)                             // Activate a tool
deactivateTool(toolId)                           // Deactivate a tool
isToolActive(toolId)                             // Check if tool is active
```

**Key behaviors**:
- Only one tool can be active at a time
- Activating a new tool automatically deactivates the current tool
- Tools are stored in a registry with their activate/deactivate functions
- Tracks the currently active tool globally

### 2. Tool Implementation (`js/tools/*.js`)

Each tool is a module that:
- Exports an `init(mapInstance)` function called during app startup
- Receives the Leaflet map instance as a dependency
- Registers itself with the tool manager
- Implements `activate()` and `deactivate()` lifecycle functions
- Manages its own UI elements and event listeners

### 3. Application Integration (`js/app.js`)

Tools are initialized during app startup:
```javascript
state.map = initializeMap();
initCoordinatesTool(state.map);  // Initialize each tool with map
```

---

## Data Flow

```
User clicks button
       ↓
Tool checks isToolActive()
       ↓
   ┌─ If active → deactivateTool()
   └─ If inactive → activateTool()
       ↓
Tool Manager deactivates current tool (if any)
       ↓
Tool Manager calls tool's activate() function
       ↓
Tool adds event listeners, shows UI, updates button state
```

---

## Why `init(mapInstance)`?

The `init(mapInstance)` function pattern serves several critical purposes:

### 1. **Dependency Injection**
The tool needs the map to add event listeners and interact with it. Passing the map as a parameter:
- Avoids global variables
- Decouples the tool from the app module
- Makes dependencies explicit

### 2. **Initialization Timing**
Tools must be initialized **after** the map is created but **before** user interaction begins:

```javascript
// Correct sequence in app.js:
state.map = initializeMap();          // 1. Create map
initCoordinatesTool(state.map);       // 2. Initialize tools with map
```

### 3. **Lifecycle Separation**
Tools have two distinct lifecycle phases:

**One-time setup** (in `init()`):
- Store map instance
- Register with tool manager
- Wire up button click handlers

**Repeated toggling** (in `activate()`/`deactivate()`):
- Add/remove map event listeners
- Show/hide UI elements
- Update button states

### 4. **Encapsulation**
The map is stored in a private module-scoped variable:

```javascript
let map = null;  // Private to this module

export function init(mapInstance) {
  map = mapInstance;  // Store once
  registerTool(TOOL_ID, activate, deactivate);
}

function activate() {
  map.on('click', clickListener);  // Use when needed
}
```

### 5. **Testability**
You can test tools by passing mock map instances without needing the full app.

---

## Creating a New Tool

Follow these steps to add a new tool to the application:

### Step 1: Create the Tool File

Create `browse-server/public/js/tools/your-tool.js`:

```javascript
import { registerTool, isToolActive, activateTool, deactivateTool } from '../ui/tool-manager.js';

const TOOL_ID = 'your-tool';
let map = null;
let eventListeners = {};

export function init(mapInstance) {
  map = mapInstance;
  
  // Register tool with tool manager
  registerTool(TOOL_ID, activate, deactivate);
  
  // Set up button and label click handlers
  const button = document.getElementById('your-tool-btn');
  const toggleTool = () => {
    if (isToolActive(TOOL_ID)) {
      deactivateTool(TOOL_ID);
    } else {
      activateTool(TOOL_ID);
    }
  };
  
  button.addEventListener('click', toggleTool);
  
  // Optional: Allow clicking the label to toggle
  const label = button.parentElement.querySelector('.tool-label');
  if (label) {
    label.addEventListener('click', toggleTool);
  }
}

function activate() {
  // 1. Update button state
  const button = document.getElementById('your-tool-btn');
  button.classList.add('active');
  
  // 2. Show any tool-specific UI
  const display = document.getElementById('your-tool-display');
  if (display) {
    display.classList.add('visible');
  }
  
  // 3. Add map event listeners
  eventListeners.click = (e) => {
    // Handle map interaction
    console.log('Tool clicked at', e.latlng);
  };
  
  map.on('click', eventListeners.click);
}

function deactivate() {
  // 1. Update button state
  const button = document.getElementById('your-tool-btn');
  button.classList.remove('active');
  
  // 2. Hide tool-specific UI
  const display = document.getElementById('your-tool-display');
  if (display) {
    display.classList.remove('visible');
    display.innerHTML = '';
  }
  
  // 3. Remove map event listeners
  if (eventListeners.click) {
    map.off('click', eventListeners.click);
    eventListeners.click = null;
  }
}
```

### Step 2: Add UI Elements to HTML

Edit `browse-server/public/index.html`, add to the `#tools` section:

```html
<div id="tools" class="tray-section">
  <h3>Tools</h3>
  
  <!-- Existing tools... -->
  
  <div class="tool-item">
    <button id="your-tool-btn" class="tool-icon-button" title="Your Tool Description">
      <span class="icon">🔧</span>
    </button>
    <label class="tool-label">Your Tool</label>
  </div>
  <div id="your-tool-display"></div>
</div>
```

### Step 3: Add Styles (if needed)

If your tool needs custom styles, add to `browse-server/public/styles.css`:

```css
#your-tool-display {
  display: none;
  margin-top: 10px;
  padding: 10px;
  background: #f0f0f0;
  border-radius: 4px;
}

#your-tool-display.visible {
  display: block;
}
```

### Step 4: Register in App

Edit `browse-server/public/js/app.js`:

```javascript
import { init as initCoordinatesTool } from './tools/coordinates-tool.js';
import { init as initYourTool } from './tools/your-tool.js';

// In DOMContentLoaded:
state.map = initializeMap();

// Initialize tools
initCoordinatesTool(state.map);
initYourTool(state.map);  // Add your tool
```

### Step 5: Test

1. Open the application in a browser
2. Click your tool button - it should activate (button shows active state)
3. Interact with the map - your event handlers should fire
4. Click the button again - tool should deactivate
5. Activate another tool - your tool should automatically deactivate

---

## Tool Best Practices

### Cleanup is Critical
Always remove event listeners in `deactivate()` to prevent memory leaks:

```javascript
// Use an eventListeners object to organize multiple listeners
let eventListeners = {};

function activate() {
  eventListeners.click = (e) => { /* ... */ };
  eventListeners.mousemove = (e) => { /* ... */ };
  
  map.on('click', eventListeners.click);
  map.on('mousemove', eventListeners.mousemove);
}

function deactivate() {
  if (eventListeners.click) {
    map.off('click', eventListeners.click);
    eventListeners.click = null;
  }
  if (eventListeners.mousemove) {
    map.off('mousemove', eventListeners.mousemove);
    eventListeners.mousemove = null;
  }
}
```

**Why use an object instead of individual variables?**
- Scales easily when adding more listeners
- Keeps module scope clean
- Groups related listeners together
- Makes the code more maintainable

### Use Descriptive Tool IDs
Tool IDs should be lowercase, hyphenated, and descriptive:
- ✅ `'coordinates'`, `'measure-distance'`, `'draw-polygon'`
- ❌ `'tool1'`, `'myTool'`, `'t'`

### Provide Visual Feedback
Always update button state and show/hide UI elements:

```javascript
function activate() {
  button.classList.add('active');
  display.classList.add('visible');
}

function deactivate() {
  button.classList.remove('active');
  display.classList.remove('visible');
}
```

### Handle Edge Cases
Check for element existence before manipulating:

```javascript
const display = document.getElementById('tool-display');
if (display) {
  display.classList.add('visible');
}
```

### Use Unique Element IDs
Every tool should have its own button and display IDs:
- `#coordinates-tool-btn`, `#coordinate-display`
- `#measure-tool-btn`, `#measure-display`

---

## Example: Coordinates Tool

**Purpose**: Click on the map to display latitude and longitude coordinates.

**File**: `browse-server/public/js/tools/coordinates-tool.js`

**Key Features**:
- Listens for map clicks
- Displays formatted coordinates in a panel
- Panel is hidden when tool is inactive
- Button shows active state with CSS class

**Code Highlights** (simplified for clarity):

```javascript
function activate() {
  // Update button state
  const button = document.getElementById('coordinates-tool-btn');
  button.classList.add('active');
  
  // Show UI
  const display = document.getElementById('coordinate-display');
  display.classList.add('visible');
  display.innerHTML = '<em>Click on the map to see coordinates...</em>';
  
  // Add map click listener
  eventListeners.click = (e) => {
    const lat = e.latlng.lat.toFixed(6);
    const lng = e.latlng.lng.toFixed(6);
    display.innerHTML = `
      <strong>Coordinates:</strong><br>
      Latitude: ${lat}<br>
      Longitude: ${lng}
    `;
  };
  map.on('click', eventListeners.click);
}
```

---

## Tool Ideas for Future Development

Here are some potential tools to add to the system:

### Measurement Tools
- **Distance Measurement**: Click two points to measure distance
- **Area Measurement**: Click multiple points to measure polygon area
- **Ruler Tool**: Drag to measure distance with live feedback

### Drawing Tools
- **Point Marker**: Click to place markers on the map
- **Line Drawing**: Click to draw polylines
- **Polygon Drawing**: Click to create custom polygons
- **Annotation Tool**: Add text labels to map locations

### Analysis Tools
- **Pixel Inspector**: Click to see raw COG pixel values
- **Color Picker**: Click to sample colors from imagery
- **Histogram Tool**: Generate histograms for selected areas
- **Profile Tool**: Draw line to see elevation/value profile

### Export Tools
- **Screenshot Tool**: Export current map view as image
- **Coordinates Export**: Export clicked coordinates as CSV/JSON
- **Bookmark Tool**: Save and restore map views

Each tool follows the same pattern: `init(mapInstance)`, `activate()`, `deactivate()`.

---

## Troubleshooting

### Tool not activating
- Check browser console for errors
- Verify tool ID is unique
- Ensure `registerTool()` is called in `init()`
- Check button ID matches what's in HTML

### Tool not deactivating when switching tools
- Verify Tool Manager is being used (don't manually toggle tools)
- Always use `activateTool()` and `deactivateTool()` from tool-manager

### Event listeners piling up
- Make sure to store listener references
- Always call `map.off()` in `deactivate()`

### Button state not updating
- Check that button ID is correct
- Verify CSS classes are defined in styles.css
- Use browser DevTools to inspect element classes

### Multiple tools active at once
- This shouldn't happen - the Tool Manager enforces single-active-tool
- If it does, check that all tools use the Tool Manager API correctly

---

## Technical Details

### Tool Registry Structure

```javascript
const tools = {
  'coordinates': {
    activate: function() { /* ... */ },
    deactivate: function() { /* ... */ }
  },
  'measure-distance': {
    activate: function() { /* ... */ },
    deactivate: function() { /* ... */ }
  }
};

let activeTool = null;  // Currently active tool ID (null when no tool is active)
```

### Event Flow

```
1. User clicks button
2. Button handler calls isToolActive(toolId)
3. If active: calls deactivateTool(toolId)
4. If inactive: calls activateTool(toolId)
5. Tool Manager:
   - Calls activeTool.deactivate() if any tool is active
   - Calls newTool.activate()
   - Updates activeTool reference
6. Tool's activate() function:
   - Updates UI
   - Adds event listeners
   - Shows tool-specific elements
```

### CSS Conventions

Tools use these CSS classes:
- `.tool-icon-button` - Styling for tool buttons
- `.tool-icon-button.active` - Active tool state
- `.tool-label` - Text label next to button
- `#tool-display.visible` - Show/hide pattern for tool panels

---

## Current Tools

| Tool | File | Purpose | Status |
|------|------|---------|--------|
| Coordinates | `coordinates-tool.js` | Display lat/lon on click | ✅ Active |

---

## Summary

The tool system provides a clean, extensible way to add interactive map features:

1. **One tool active at a time** - prevents conflicts
2. **Consistent pattern** - easy to add new tools
3. **Proper cleanup** - no memory leaks
4. **Clear lifecycle** - init → activate → deactivate
5. **Dependency injection** - tools receive map instance

To add a new tool: create file, implement pattern, add to HTML, register in app.js.
