# Deeptime North Star

## Purpose

Deeptime should become a general-purpose evidence pipeline for marine stakeholders.

The long-term product is not just a map viewer. Deeptime should help users assemble, inspect, analyze, and publish defensible marine evidence across ecology, fisheries, ocean conditions, governance, and stakeholder knowledge. Every output should be connected back to its sources, assumptions, transformations, and caveats.

## Product Vision

Deeptime should behave like a mix of:

- a marine layer catalog
- a spatial analysis workspace
- a source-linked research notebook
- an evidence publishing system
- a provenance-aware decision-support tool

Users should be able to ask practical questions about a marine place or issue, then receive maps, tables, charts, summaries, and exportable evidence packages that can be reviewed by scientists, managers, fishers, communities, advocates, funders, and policy teams.

Example target questions:

- Where do whale habitat, migration, and fisheries activity overlap?
- Which fishing communities or gear types may be affected by a proposed management area?
- Which sources support a conservation or permitting decision, and how current are they?
- How do ecological significance, human use, and governance boundaries interact in a candidate area?
- What evidence is missing, uncertain, stale, or contested?

## Core Principles

1. The map is the front door, not the whole product.
2. Every layer and output should be source-linked, inspectable, and reproducible.
3. Deterministic code owns scientific and geospatial transformations.
4. Language models may help plan, retrieve, summarize, and review, but they should not become the source of truth.
5. Uncertainty, missingness, source quality, and assumptions should be visible by default.
6. The platform should support common research formats: GeoJSON, CSV, GeoTIFF, NetCDF, GeoPackage, Shapefile, PDF, and citation exports.
7. Public datasets, partner datasets, and researcher-contributed data should use the same evidence model.
8. The open-source core should be useful even without hosted Deeptime infrastructure.

## Stakeholders

- Marine researchers and conservation scientists
- Fisheries and bycatch researchers
- Fishery managers and fishing organizations
- Marine spatial planners
- Coastal and ocean-management agencies
- Tribal, Indigenous, and coastal community partners
- Protected-area and restoration practitioners
- Conservation NGOs and advocacy teams
- Offshore wind, permitting, and environmental review teams
- Funders and implementing partners evaluating marine interventions

## Evidence Families

Deeptime should organize evidence around durable source families rather than one-off project folders.

1. Species occurrence, habitat, migration, and risk
2. Fisheries activity, landings, gear, and management areas
3. Vessel behavior and ocean-use intensity
4. Oceanographic and environmental context
5. Protected areas, jurisdiction, and governance boundaries
6. Human communities, ports, working waterfronts, and economic context
7. Evidence and policy documents
8. Researcher-contributed observations, analyses, and local knowledge

The first MVP should cover only a small subset. The architecture should still avoid hard-coding Deeptime around Oregon, whales, fisheries, rasters, or any single source provider.

## Ideal Server Architecture

The north-star architecture should be modular. Deeptime should not become one large map server that owns ingestion, analysis, exports, AI, and collaboration in one process.

```text
Frontend clients
  -> App API
      -> Layer and source catalog
      -> Tile and feature services
      -> Workspace and saved-view service
      -> Workflow and job service
      -> Dossier and export service

Workflow and job service
  -> Source import workers
  -> Deterministic analysis workers
  -> Provenance writer
  -> AI planning and review service

Storage
  -> Postgres/PostGIS for queryable spatial records
  -> pgvector or external index for source/document retrieval when needed
  -> Object storage for source snapshots, rasters, generated artifacts, and exports
```

Primary service boundaries:

- Frontend clients: MapLibre map, lightweight embeds, evidence dossier views, and scripted API clients.
- App API: workspaces, saved views, candidate areas, permissions, comments, review state, and orchestration entry points.
- Layer and source catalog: layer definitions, source metadata, citations, licenses, update cadence, source versions, known limitations, and available assets.
- Tile and feature services: raster tiles, vector features, and eventually vector tiles without exposing storage details to clients.
- Workflow and job service: asynchronous imports, spatial joins, area summaries, exports, dossier generation, retries, and job status.
- Source import workers: download, snapshot, validate, normalize, clip, simplify, and hash incoming datasets.
- Deterministic analysis workers: Python, R, GDAL, and PostGIS workflows for scientific and geospatial transformations.
- Provenance writer: lineage records for sources, retrieval dates, parameters, transformations, assumptions, uncertainty, artifacts, and workflow versions.
- AI planning and review service: source-grounded planning, tool selection, ambiguity checks, synthesis, and output review.
- Dossier and export service: evidence bundles, maps, charts, CSV, GeoJSON, GeoTIFF, PDF, and citation packages.

The current repository implements only a small part of this future shape: a browser map server, static frontend assets, a raster tile path, and deployment scripts. The next step is to turn that foundation into a source-agnostic map and layer API.

## Product Layers

### 1. Mapping Substrate

Build a stable map and layer contract before adding analysis complexity.

The near-term substrate should support:

- a base map suitable for marine and coastal context
- raster and vector overlays through one layer API
- grouped layer controls
- legends and styling metadata
- feature inspection
- source and caveat display
- saved views that can be shared or embedded

MapLibre should become the primary map interface for layer-rich work. Leaflet can remain useful for lightweight embedded views.

### 2. Source And Layer Catalog

Introduce source metadata early, even if the first implementation is static JSON.

Each source should track:

- source identity
- provider
- source URL or local snapshot path
- license and citation
- retrieval date
- source version or publication date
- update frequency
- geographic and temporal coverage
- transformations applied by Deeptime
- known limitations and appropriate-use notes

The catalog is the backbone of the evidence pipeline. The UI, API, analyses, and exports should all read from it rather than duplicating source assumptions.

### 3. Provenance Model

Every map, chart, summary, export, or dossier should be able to answer:

- What sources were used?
- When were they retrieved or uploaded?
- What transformations were applied?
- What parameters were selected?
- What assumptions were introduced?
- What uncertainties or missing data remain?
- What code or workflow produced the output?

Provenance should be a user-facing product feature, not only an internal log.

### 4. Deterministic Analysis Layer

Scientific and management analysis should be explicit, testable code.

Core deterministic capabilities:

- spatial joins and overlays
- area summaries
- temporal aggregation
- source normalization
- taxonomic reconciliation
- management-boundary lookup
- hotspot and overlap detection
- trend analysis where source data supports it
- export packaging
- dossier compilation

These workflows should be callable by the UI, by scripts, and eventually by AI planning tools.

### 5. Evidence Workspace

Once layers and deterministic analysis exist, Deeptime can become a workspace for marine issues, places, and decisions.

Workspace records should collect:

- area geometry
- relevant layers
- evidence summaries
- source links
- generated figures
- uncertainty notes
- stakeholder notes
- exports
- provenance reports
- review status and history

The most important long-term output is a living, source-linked evidence dossier.

### 6. AI Planning And Review

AI should be added after the layer catalog, provenance model, and deterministic tools are stable enough to constrain it.

The intended role of AI:

- interpret natural-language questions
- identify relevant sources and workflows
- build a structured analysis plan
- call deterministic tools
- summarize source-linked results
- flag uncertainty and ambiguity
- review outputs from a fresh context

The model should not silently invent evidence, run hidden analysis, or produce unsupported recommendations.

## Phased Plan

### Phase 0: Current Foundation

Status: partially built.

Deeptime has a lightweight browser mapping foundation and a raster tile path. This is useful infrastructure, but the product should now be framed as a general marine evidence pipeline.

### Phase 1: Oregon Coast Whale And Fisheries MVP

Goal: prove the evidence-map pattern with a concrete, stakeholder-relevant use case.

Deliverables:

- PNW/Oregon coast base map
- Oregon coastal and territorial-sea context layers
- whale ecology layers
- Oregon fisheries layers
- source metadata for every layer
- grouped layer controls
- feature inspection
- basic saved view

This phase is described in [mapping-mvp.md](mapping-mvp.md).

### Phase 2: Provenance-First Layer Catalog

Goal: make each layer scientifically and operationally legible.

Deliverables:

- layer metadata schema
- source citation and license fields
- retrieval or generated timestamps
- source hashes for local files
- known limitations fields
- transformation metadata
- evidence-family tags

Static files are acceptable at first. The schema matters more than the storage backend.

### Phase 3: Deterministic Analysis And Export Jobs

Goal: produce reproducible outputs from explicit workflows.

Deliverables:

- small job runner or workflow API
- spatial overlap workflow
- area summary workflow
- temporal aggregation workflow where source data supports it
- GeoJSON and CSV export workflow
- provenance report for each generated output
- tests around deterministic transformations

This is the first phase where Deeptime becomes more than a viewer.

### Phase 4: Evidence Dossiers

Goal: package evidence into a durable research and decision-support object.

Deliverables:

- dossier model
- generated map snapshots or saved views
- evidence tables
- source and methods summary
- uncertainty and missingness section
- downloadable evidence bundle

The initial dossier can be plain HTML, Markdown, or PDF. Native format is less important than reproducibility and provenance.

### Phase 5: Stakeholder-Contributed Data

Goal: let users bring their own evidence into the same model.

Deliverables:

- upload path for GeoJSON and small tabular files
- validation and normalization
- uploaded source metadata
- provenance capture
- private or local-only workspace boundary
- display as ordinary layers in the mapping API

This is a critical bridge from atlas to workspace.

### Phase 6: AI-Assisted Planning And Review

Goal: make evidence workflows easier to run without weakening scientific rigor.

Deliverables:

- structured query planning
- tool selection over deterministic workflows
- source-grounded synthesis
- provenance-only review
- output review
- ambiguity and assumption prompts
- human approval checkpoints before publication or sharing

AI should enter as a planner and reviewer around existing workflows, not as a replacement for them.

### Phase 7: Collaboration, Publication, And Sustainability

Goal: support real external use.

Deliverables:

- shared workspaces
- comments and review status
- publication-ready exports
- citation bundles
- stable open-source releases
- documentation for external deployments
- governance and contribution guidelines
- hosted support model or institutional deployment path

## Near-Term Development Bias

Prefer work that moves Deeptime toward the evidence pipeline while keeping the first implementation small.

Good next steps:

- normalize MVP sources into one layer API
- keep frontends source-agnostic
- include source metadata and caveats from the start
- keep saved views portable as JSON
- keep analysis out of the UI until deterministic workflows exist
- choose Oregon data sources that can be replaced or extended without frontend changes

Avoid for now:

- natural-language query UI before deterministic tools exist
- a large database migration before the layer contract is proven
- hard-coded assumptions that only fit one Oregon dataset
- opaque AI-generated scores or recommendations
- export and dossier workflows before layer provenance is reliable

## Success Measures

Near-term success:

- users can view whale ecology and fisheries layers together on the Oregon coast
- layer records carry source metadata and caveats
- users can inspect features and understand where each layer came from
- saved views can be shared or embedded
- the architecture can add new layer providers without frontend rewrites

Medium-term success:

- users can generate reproducible area summaries
- outputs include provenance reports
- deterministic workflows are tested
- researchers can export data in familiar formats
- contributed data can be validated and displayed

Long-term success:

- external stakeholders use Deeptime to assemble marine evidence packages
- dossiers are credible enough for scientific, management, and policy review
- outputs can support conservation, fisheries, permitting, restoration, and planning workflows
- open-source components can be reused outside the hosted product
- AI reduces workflow friction without reducing evidence quality

## Open Questions

- Which Oregon fisheries layer should be the first canonical MVP layer?
- Which whale ecology source should be treated as the primary public reference layer?
- What is the minimum useful source metadata schema for MVP?
- Should the first persistent catalog be PostGIS, static files plus generated artifacts, or a hybrid?
- Which deterministic analysis should follow the MVP first: spatial overlap, area summary, or source comparison?
- Which outputs matter first for users: interactive maps, downloadable data, narrative dossiers, or publication figures?
