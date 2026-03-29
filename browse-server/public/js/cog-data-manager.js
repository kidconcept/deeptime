const TITILER_URL = '/api/titiler';

const COG_FILES = [
  { url: 'gs://deeptime-cogs-deeptime-491316/18palms_georef_qgis-cog.tif', name: 'Georeferenced' },
  { url: 'gs://deeptime-cogs-deeptime-491316/18palms-ungeoref.tif', name: 'Unreferenced' },
  { url: 'gs://deeptime-cogs-deeptime-491316/18palms.tif', name: 'Original (Invalid Georef)' },
];

export async function fetchAllCogMetadata() {
  const promises = COG_FILES.map(cog => {
    const url = `${TITILER_URL}/cog/info?url=${encodeURIComponent(cog.url)}&v=${Date.now()}`;
    return fetch(url)
      .then(res => res.json())
      .then(info => ({
        url: cog.url,
        name: info.metadata?.SITE_NAME || cog.name,
        info: info
      }))
      .catch(error => {
        console.error(`Failed to fetch info for ${cog.url}`, error);
        return { url: cog.url, name: cog.name, info: null };
      });
  });
  return Promise.all(promises);
}

export async function getCogInfo(url) {
    const infoUrl = `${TITILER_URL}/cog/info?url=${encodeURIComponent(url)}&v=${Date.now()}`;
    const response = await fetch(infoUrl);
    if (!response.ok) {
        throw new Error(`Failed to fetch COG info: ${response.statusText}`);
    }
    const info = await response.json();
    
    // Basic validation
    if (!info.bounds || info.bounds.length !== 4) {
        throw new Error('Invalid bounds in COG metadata');
    }

    return info;
}
