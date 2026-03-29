export async function fetchCogConfig() {
  try {
    const response = await fetch('/cogs.json');
    if (!response.ok) {
      throw new Error(`Failed to fetch cogs.json: ${response.statusText}`);
    }
    const config = await response.json();
    return config;
  } catch (error) {
    console.error('Could not load COG configuration.', error);
    // Return an empty array on error so the app doesn't crash.
    return [];
  }
}
