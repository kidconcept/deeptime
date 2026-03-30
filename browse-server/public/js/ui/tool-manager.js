// Simple tool activation manager
// Only one tool can be active at a time

const tools = {};
let activeTool = null;

export function registerTool(toolId, activateFn, deactivateFn) {
  tools[toolId] = {
    activate: activateFn,
    deactivate: deactivateFn
  };
}

export function activateTool(toolId) {
  if (!tools[toolId]) {
    console.warn(`Tool ${toolId} not registered`);
    return;
  }

  // Deactivate current tool if any
  if (activeTool && activeTool !== toolId) {
    deactivateTool(activeTool);
  }

  // Activate the new tool
  tools[toolId].activate();
  activeTool = toolId;
}

export function deactivateTool(toolId) {
  if (!tools[toolId]) {
    console.warn(`Tool ${toolId} not registered`);
    return;
  }

  tools[toolId].deactivate();
  
  if (activeTool === toolId) {
    activeTool = null;
  }
}

export function isToolActive(toolId) {
  return activeTool === toolId;
}
