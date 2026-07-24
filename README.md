# deeptime

Deeptime is a general-purpose evidence pipeline for marine stakeholders.

The project exists to help teams find, normalize, visualize, analyze, and publish marine evidence with clear source lineage. The map is the first interface, but the long-term product is an evidence system: layers, source records, deterministic analysis, provenance, and decision-ready outputs that can be inspected and reproduced.

## Direction

Deeptime is a general marine evidence system. Earlier repo assets remain useful as technical precedent, especially for raster delivery and browser-based map exploration, but the product direction is broader.

The intended users include marine researchers, fisheries teams, coastal managers, conservation practitioners, NGOs, planners, funders, and policy teams who need to compare ecological, human-use, and governance evidence.

The near-term MVP is an Oregon coast map that overlays whale ecology data and fisheries data. That slice should prove the core pattern: source-backed layers, lightweight inspection, transparent caveats, and a map experience that can later support more regions, sources, analyses, and stakeholders.

## Product Shape

Deeptime should grow around a few durable capabilities:

- source intake for public, partner, and researcher-contributed marine datasets
- a layer catalog with citations, licenses, update cadence, transformations, and known limitations
- a map interface for exploring ecological, human-use, and governance layers
- deterministic geospatial workflows for summaries, overlays, trends, and exports
- provenance records for every derived output
- evidence dossiers that package maps, tables, methods, caveats, and source links
- AI-assisted planning and review only after deterministic tools and provenance constraints exist

## Current Technical Foundation

The repository currently contains a lightweight browser mapping foundation:

- `browse-server/` is a Node/Express app that serves the browser UI and API routes.
- The existing Leaflet viewer can be reused as a lightweight map surface or saved-view embed.
- The TiTiler and Cloud Optimized GeoTIFF path can remain available for raster evidence layers.
- Deployment scripts exist for the current browse and tile services, but they are implementation tooling rather than the product frame.

Future work should adapt this foundation toward a source-agnostic layer API and a MapLibre-first evidence map.

## Documentation

- [North star](documentation/north-star.md)
- [MVP](documentation/mapping-mvp.md)

## Near-Term Work

1. Define the Oregon coast MVP layer catalog.
2. Acquire and normalize the first whale ecology and fisheries datasets.
3. Build a source-agnostic layer API.
4. Render the MVP map with clear layer groups, legends, feature inspection, and source metadata.
5. Keep the data model general enough that Oregon is the first use case, not a hard-coded product boundary.
