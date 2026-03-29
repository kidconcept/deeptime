# Metadata Display

A new section has been added below the COG selector to display relevant metadata from the selected COG. This will help in debugging and understanding the properties of each file.

- **`COG Type`**: Indicates the georeferencing status:
  - `Properly Georeferenced`: Real-world lat/lon coordinates.
  - `Arbitrarily Georeferenced`: Has valid geographic bounds, but they are not tied to real-world locations (e.g., anchored at 0,0).
  - `Not Georeferenced`: Lacks valid geographic bounds and will be displayed in a fallback preview mode.
- **`Site Name`**: The `SITE_NAME` from the COG's metadata, if available.
- **`Scale`**: The `SCALE_M_PER_PX` (meters per pixel) from the metadata.
- **`Zoom`**: The recommended zoom range (`min-max`) and the native zoom level from the metadata.
- **`Bounds`**: The geographic bounding box of the COG.
