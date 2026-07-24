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
8. Ryu should be the public source catalog and discovery layer, not the owner of Deeptime user credentials.
9. Deeptime should own user and workspace auth, provider credentials, source access execution, generated assets, transformations, and provenance.
10. The open-source core should be useful even without hosted Deeptime infrastructure.

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

Early implementations can cover only a small subset. The architecture should still avoid hard-coding Deeptime around any one region, species group, stakeholder, data type, or source provider.

## Ideal Server Architecture

The north-star architecture should be modular. Deeptime should not become one large map server that owns discovery, authentication, ingestion, analysis, exports, AI, and collaboration in one process.

Ryu and Deeptime should have a clean boundary:

- **Ryu** is the public catalog and discovery layer for marine data sources. It exposes source records, provider records, endpoint templates, access requirements, supported formats, citations, licenses, caveats, update cadence, and public source-health signals through API and MCP surfaces.
- **Deeptime** owns users, workspaces, provider connections, credentials, source access execution, transformations, generated assets, provenance, map experiences, evidence workspaces, analysis jobs, dossiers, and exports.

Ryu should not store Deeptime user secrets or decide workspace-specific permissions. Deeptime may use Ryu to discover how a source can be accessed, but Deeptime should execute that access using Deeptime-owned user or workspace credentials.

```text
Ryu public catalog API/MCP
  -> indexes external data providers
  -> exposes provider records
  -> exposes source records
  -> exposes endpoint templates
  -> exposes auth requirements
  -> exposes licenses, citations, caveats
  -> exposes public source-health signals

Frontend clients
  -> Deeptime App API
      -> User and workspace auth
      -> Provider connections and credentials
      -> Source access executor
      -> Workspace layer catalog
      -> Tile and feature services
      -> Workspace and saved-view service
      -> Workflow and job service
      -> Dossier and export service

Workflow and job service
  -> Source fetch and import workers
  -> Deterministic analysis workers
  -> Provenance writer
  -> AI planning and review service

Storage
  -> Postgres/PostGIS for queryable spatial records
  -> pgvector or external index for source/document retrieval when needed
  -> secret storage for provider credentials and refresh tokens
  -> Object storage for source snapshots, rasters, generated artifacts, and exports
```

Primary service boundaries:

- Frontend clients: MapLibre map, lightweight embeds, evidence dossier views, and scripted API clients.
- Ryu public catalog API/MCP: provider and source discovery, endpoint templates, access requirements, supported formats, citations, licenses, caveats, update cadence, and public health signals. Ryu does not store Deeptime user secrets or workspace permissions.
- Deeptime App API: users, workspaces, saved views, candidate areas, permissions, comments, review state, provider connections, source access requests, and orchestration entry points.
- Provider connections and credentials: Deeptime-managed OAuth connections, API keys, refresh tokens, service accounts, access policies, and short-lived internal access grants.
- Workspace layer catalog: layer definitions derived from Ryu source records, Deeptime-generated assets, workspace-specific visibility, styles, provenance links, and known limitations.
- Tile and feature services: raster tiles, vector features, and eventually vector tiles without exposing storage details to clients.
- Workflow and job service: asynchronous imports, spatial joins, area summaries, exports, dossier generation, retries, and job status.
- Source fetch and import workers: use Deeptime-owned provider credentials to download, query, snapshot, validate, normalize, clip, simplify, and hash incoming datasets.
- Deterministic analysis workers: Python, R, GDAL, and PostGIS workflows for scientific and geospatial transformations.
- Provenance writer: lineage records for sources, retrieval dates, parameters, transformations, assumptions, uncertainty, artifacts, and workflow versions.
- AI planning and review service: source-grounded planning, tool selection, ambiguity checks, synthesis, and output review.
- Dossier and export service: evidence bundles, maps, charts, CSV, GeoJSON, GeoTIFF, PDF, and citation packages.

Implementations should be allowed to start small, but the architecture should keep a clear path from simple map layers to source catalogs, deterministic workflows, provenance, and evidence dossiers.

### Ryu-Deeptime Handshake

The default handshake should be catalog-only from Ryu and auth-aware from Deeptime.

1. Deeptime asks Ryu for sources relevant to a place, theme, provider, format, or evidence family.
2. Ryu returns public `SourceCatalogRecord` objects with provider metadata, endpoint templates, access requirements, supported formats, license, citation, caveats, and update cadence.
3. Deeptime checks whether the current user or workspace has the required provider connection.
4. If credentials are required, Deeptime prompts for or uses a Deeptime-managed provider connection.
5. Deeptime fetches or queries the source directly from Deeptime backend services or approved browser paths.
6. Deeptime snapshots, transforms, stores, and serves generated assets.
7. Deeptime records provenance linking generated assets and evidence outputs back to Ryu source IDs.

This keeps Ryu reusable as a public marine source catalog while allowing Deeptime to support multiple users with different credentials across the same providers.

## Product Layers

### 1. Mapping Substrate

Build a stable map and layer contract before adding analysis complexity.

The mapping substrate should support:

- a base map suitable for marine and coastal context
- raster and vector overlays through one layer API
- grouped layer controls
- legends and styling metadata
- feature inspection
- source and caveat display
- saved views that can be shared or embedded

MapLibre should become the primary map interface for layer-rich work. Leaflet can remain useful for lightweight embedded views.

### 2. Source Discovery And Layer Catalog

Separate public source discovery from Deeptime-specific access and use.

Ryu should track public catalog fields:

- source identity
- provider
- source URL, endpoint template, or documentation URL
- access method and auth requirement
- license and citation
- source version or publication date
- update frequency
- geographic and temporal coverage
- supported formats
- public health or availability status
- known limitations and appropriate-use notes

Deeptime should track use-specific fields:

- user and workspace provider connections
- credentials and refresh status
- source access attempts
- retrieval date
- source snapshots
- generated layer assets
- transformations applied by Deeptime
- workspace-specific layer settings
- source-use provenance records

Ryu is the discovery catalog. Deeptime is the auth, access, transformation, provenance, and product system.

### 3. Provenance Model

Every map, chart, summary, export, or dossier should be able to answer:

- What sources were used?
- Which Ryu source IDs did they come from?
- When were they retrieved or uploaded?
- Which Deeptime user or workspace credentials were used, where relevant?
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

## Strategic Roadmap

### 1. Mapping Substrate

Goal: make marine evidence visible and inspectable through a stable layer contract.

Capabilities:

- source-agnostic layer records
- raster and vector delivery
- map styles and legends
- feature inspection
- saved views
- source and caveat display

### 2. Catalog-Linked Layer And Access Model

Goal: make each layer scientifically, operationally, and permission-wise legible.

Deliverables:

- Ryu `SourceCatalogRecord` integration
- Deeptime provider-connection model
- workspace source-use policy
- source access audit records
- layer metadata schema
- source citation and license fields
- retrieval or generated timestamps
- source hashes for local files
- known limitations fields
- transformation metadata
- evidence-family tags

Static files are acceptable at first for layer records. User/provider credentials and access records should live in Deeptime-controlled auth and storage systems.

### 3. Deterministic Analysis And Export Jobs

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

### 4. Evidence Dossiers

Goal: package evidence into a durable research and decision-support object.

Deliverables:

- dossier model
- generated map snapshots or saved views
- evidence tables
- source and methods summary
- uncertainty and missingness section
- downloadable evidence bundle

The initial dossier can be plain HTML, Markdown, or PDF. Native format is less important than reproducibility and provenance.

### 5. Stakeholder-Contributed Data

Goal: let users bring their own evidence into the same model.

Deliverables:

- upload path for GeoJSON and small tabular files
- validation and normalization
- uploaded source metadata
- provenance capture
- private or local-only workspace boundary
- display as ordinary layers in the mapping API

This is a critical bridge from atlas to workspace.

### 6. AI-Assisted Planning And Review

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

### 7. Collaboration, Publication, And Sustainability

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

## Development Bias

Prefer work that moves Deeptime toward the evidence pipeline while keeping implementation choices reversible.

Good next steps:

- normalize sources into one layer API
- keep Ryu as the public catalog and Deeptime as the auth/access executor
- keep frontends source-agnostic
- include source metadata and caveats from the start
- keep saved views portable as JSON
- keep analysis out of the UI until deterministic workflows exist
- choose source integrations that can be replaced or extended without frontend changes

Avoid for now:

- natural-language query UI before deterministic tools exist
- a large database migration before the layer contract is proven
- hard-coded assumptions that only fit one dataset, region, or provider
- Ryu-owned user secrets or workspace-specific permissions
- opaque AI-generated scores or recommendations
- export and dossier workflows before layer provenance is reliable

## Success Measures

Product success:

- layer records carry source metadata and caveats
- users can inspect features and understand where each layer came from
- saved views can be shared or embedded
- the architecture can add new layer providers without frontend rewrites

Evidence success:

- users can generate reproducible area summaries
- outputs include provenance reports
- deterministic workflows are tested
- researchers can export data in familiar formats
- contributed data can be validated and displayed

Platform success:

- external stakeholders use Deeptime to assemble marine evidence packages
- dossiers are credible enough for scientific, management, and policy review
- outputs can support conservation, fisheries, permitting, restoration, and planning workflows
- open-source components can be reused outside the hosted product
- AI reduces workflow friction without reducing evidence quality

## Open Questions

- What is the minimum useful source metadata schema?
- What provider-connection model does Deeptime need for multi-user source auth?
- Which source fields belong in Ryu, and which source-use fields belong only in Deeptime?
- What Deeptime storage boundary should hold workspace layer records, source-use records, and generated artifacts?
- Which deterministic analysis should be implemented first: spatial overlap, area summary, or source comparison?
- Which outputs matter first for users: interactive maps, downloadable data, narrative dossiers, or publication figures?
