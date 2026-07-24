# Deeptime MVP: Oregon Coast Marine Evidence Map

## Purpose

The MVP should prove Deeptime as a general marine evidence pipeline by focusing on one concrete use case: the Oregon coast.

The product should display a base map of the Pacific Northwest and Oregon coast, then overlay whale ecology data and Oregon fisheries data with clear source metadata. The goal is not to finish the full evidence platform. The goal is to show that Deeptime can turn heterogeneous marine datasets into an inspectable, source-backed map experience for real stakeholders.

## MVP Outcome

A user can open Deeptime, view the Oregon coast, toggle whale ecology and fisheries layers, inspect features, see where each layer came from, and understand major caveats before using the map in a conversation or planning workflow.

The MVP should answer early questions like:

- Where are important whale ecology areas along the Oregon coast?
- Which fisheries activity or management layers occupy the same coastal waters?
- What source produced each layer, how current is it, and what are its limitations?
- Which areas deserve deeper deterministic analysis after the map proves useful?

## Scope

Include:

- PNW/Oregon coast base map
- Oregon coastline and territorial-sea context
- whale ecology layers
- Oregon fisheries layers
- grouped layer controls
- legends
- feature inspection
- source, citation, license, retrieval date, and caveat display
- one or more static saved views

Do not include yet:

- user accounts
- editing or uploads
- live data refresh jobs
- deterministic overlap analysis
- exports and dossiers
- AI-assisted planning
- PostGIS or vector tile infrastructure unless the static-file approach fails

## First Layer Stack

The MVP should start with public or semi-public sources that are credible, spatial, and practical to normalize.

| Family | Source | MVP Role | Notes |
| --- | --- | --- | --- |
| Base/context | Oregon DLCD coastal and territorial sea GIS data | Oregon coastline, territorial sea, planning boundaries | Use for grounding the map in Oregon jurisdiction and coastal context. |
| Whale ecology | NOAA Biologically Important Areas II | Cetacean feeding, migration, reproduction, and resident-population areas | Strong first whale layer because it is explicitly ecological and designed for spatial interpretation. |
| Whale ecology | NOAA Environmental Sensitivity Index Outer Coast Washington/Oregon marine mammal polygons | Whale and marine mammal distribution, concentration, and migratory polygons | Useful Oregon-specific biological context; treat as planning/evidence data, not legal boundaries. |
| Whale ecology | NOAA West Coast critical habitat GIS data | Regulatory context for listed species such as humpback whale and Southern Resident killer whale | Good secondary context layer; clearly separate legal/designation data from ecology observations. |
| Fisheries | Ecotrust Oregon Marine Fisheries Uses and Values Project | Oregon fishery-use and value layers, especially Dungeness crab | Strong Oregon-specific fisheries layer; older but highly relevant to ocean-use planning. |
| Fisheries | ODFW commercial landing statistics | Port-level pounds and value by fishery | Good for port popups or proportional symbols; not an offshore effort footprint. |
| Fisheries | NOAA West Coast groundfish conservation areas | Fisheries management closures and conservation areas | Good management context for commercial fisheries. |
| Fisheries, later | NOAA Pacific Fishing Effort Mapping Project | Higher-resolution fisheries effort, catch, landings, and economic patterns | Valuable next source if underlying services are practical to access and license. |
| Vessel activity, later | Global Fishing Watch apparent fishing effort | AIS-derived fishing activity heatmaps | Useful but should follow the static MVP because it adds account, API, and interpretation complexity. |

Reference links:

- [Oregon DLCD maps and coastal data](https://www.oregon.gov/lcd/about/pages/maps-data-tools.aspx)
- [Oregon Territorial Sea Plan GIS service](https://gis.lcd.state.or.us/server/rest/services/Framework/AdminBounds_TerritorialSeaPlan/MapServer)
- [NOAA Biologically Important Areas](https://oceannoise.noaa.gov/biologically-important-areas)
- [NOAA West Coast critical habitat GIS data](https://www.fisheries.noaa.gov/resource/map/critical-habitat-maps-and-gis-data-west-coast-region)
- [NOAA Species and Habitat App](https://www.fisheries.noaa.gov/resource/map/species-and-habitat-app)
- [NOAA ESI Outer Coast Washington/Oregon marine mammal polygons](https://www.fisheries.noaa.gov/inport/item/55730)
- [Ecotrust Oregon Marine Fisheries Uses and Values Project](https://offshorewind.westcoastoceans.org/orowindmap-data-catalog/fishing-ecotrust-uses-and-values-project/)
- [ODFW commercial landing statistics](https://www.dfw.state.or.us/fish/commercial/landing_stats/2024/index.asp)
- [NOAA Pacific Fishing Effort Mapping Project](https://www.fisheries.noaa.gov/feature-story/new-system-maps-and-charts-west-coast-fisheries-data-inform-decisions-ocean-uses)
- [Global Fishing Watch apparent fishing effort](https://globalfishingwatch.org/dataset-and-code-fishing-effort/)

## MVP Data Pipeline

The MVP should use a small, repeatable static pipeline before introducing heavier infrastructure.

1. Source selection: choose the first whale, fisheries, and Oregon context layers.
2. Source snapshot: store the downloaded source file or record the source service URL and retrieval date.
3. Normalization: convert shapefiles, file geodatabases, or CSVs into web-ready GeoJSON where practical.
4. Clipping: limit large regional layers to the Oregon coast area of interest.
5. Simplification: reduce geometry weight enough for browser rendering while preserving useful shape.
6. Metadata: create one source record per layer with citation, license, retrieval date, transformation notes, and caveats.
7. Serving: expose all layers through one API contract.
8. Rendering: show layers in the map without the frontend knowing the original source format.

## Suggested File Layout

Keep MVP sources and generated web assets under the browse-server boundary until the layer contract is proven.

```text
browse-server/
  sources/
    oregon-coast/
      dlcd/
      noaa-bia/
      noaa-esi/
      noaa-critical-habitat/
      ecotrust-fisheries/
      odfw-landings/
      noaa-groundfish/
  public/
    data/
      oregon-coast/
    layer-catalog.json
    views.json
```

The exact folders can change during implementation. The important boundary is that frontend code reads API responses, not raw source directories.

## Layer Catalog Contract

Each layer should expose enough information to render the map and support source review.

```json
{
  "id": "noaa_bia_humpback_whale_oregon",
  "name": "Humpback Whale Biologically Important Areas",
  "family": "whale_ecology",
  "kind": "vector_layer",
  "geometryType": "Polygon",
  "defaultVisible": true,
  "dataUrl": "/data/oregon-coast/noaa_bia_humpback_whale_oregon.geojson",
  "source": {
    "provider": "NOAA",
    "title": "Biologically Important Areas II",
    "url": "https://oceannoise.noaa.gov/biologically-important-areas",
    "retrievedAt": "TBD",
    "license": "TBD",
    "citation": "TBD"
  },
  "provenance": {
    "snapshot": "TBD",
    "transform": "download -> convert -> clip_to_oregon_coast -> simplify",
    "generatedAt": "TBD"
  },
  "caveats": [
    "Planning and evidence layer; verify authoritative source before regulatory use.",
    "Geometry may be simplified for browser rendering."
  ],
  "style": {
    "fillColor": "#2b8cbe",
    "fillOpacity": 0.22,
    "lineColor": "#045a8d",
    "lineWidth": 1
  }
}
```

## API Shape

Use a source-agnostic API from the start.

### `GET /api/layers`

Returns the MVP layer catalog.

Layer records should include:

- `id`
- `name`
- `family`
- `kind`
- `geometryType`
- `defaultVisible`
- `dataUrl` or tile URL
- `source`
- `provenance`
- `caveats`
- `style`

### `GET /api/layers/:layerId`

Returns one layer record.

### `GET /api/layers/:layerId/features`

Returns GeoJSON for vector layers where the MVP serves local static features.

### `GET /api/views`

Returns static saved views, including an Oregon coast default view.

## Map Experience

The first screen should be the working map, not a landing page.

Map requirements:

- full-viewport map centered on the Oregon coast
- marine-appropriate base map with coastline, labels, and bathymetric or ocean context where available
- layer panel grouped by `Whale ecology`, `Fisheries`, `Boundaries`, and `Context`
- visible legends for active layers
- feature popup or side panel with selected feature attributes
- source panel showing provider, citation, retrieval date, license, and caveats
- saved default view for the Oregon coast

The interface should be pragmatic and compact. This is an evidence tool for repeated use, not a marketing site.

## Implementation Bias

Use the current lightweight server until it becomes a constraint.

Recommended first implementation:

- keep Node/Express as the app server
- add source-agnostic layer API routes
- use static JSON for the first catalog
- use generated GeoJSON for the first vector layers
- use MapLibre for the primary map
- keep Leaflet only if useful for existing viewer compatibility or lightweight embeds
- defer PostGIS until the MVP has too much data or needs real spatial queries
- defer vector tiles until GeoJSON payloads are too heavy

## Acceptance Criteria

- The map opens centered on the Oregon coast.
- A PNW/Oregon coastal base map is visible.
- At least one Oregon boundary/context layer is available.
- At least two whale ecology layers are available.
- At least two fisheries or fisheries-context layers are available.
- Layers are grouped and can be toggled independently.
- A user can click a feature and inspect useful attributes.
- Every layer shows source provider, source URL, retrieval date placeholder or value, citation placeholder or value, license placeholder or value, and caveats.
- The frontend does not depend on raw source file names or source directory layout.
- The MVP design can support another region by adding sources and catalog records rather than rewriting the map.

## Deferred Until After MVP

- live source refresh
- authenticated workspaces
- uploads and stakeholder-contributed data
- deterministic overlap scores
- analysis jobs
- map exports
- evidence dossiers
- AI-assisted planning
- PostGIS-backed catalog
- vector tile service
- Global Fishing Watch integration
- NOAA Pacific Fishing Effort service integration
