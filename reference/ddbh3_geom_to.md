# Convert polygon or linestring geometries to H3 cell representations

Convert polygon or linestring geometries into the H3 cells that
intersect them, at a specified resolution. Input must be a
`duckspatial_df`, `sf`, or table with POLYGON/MULTIPOLYGON or
LINESTRING/MULTILINESTRING geometries

## Usage

``` r
ddbh3_polygons_to_spatial(
  x,
  resolution,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE,
  containment = "overlap"
)

ddbh3_lines_to_spatial(
  x,
  resolution,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE,
  containment = "overlap",
  buffer_scale = 1
)

ddbh3_polygons_to_h3(
  x,
  resolution,
  new_column = "h3string",
  h3_format = "string",
  containment = "overlap",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_lines_to_h3(
  x,
  resolution,
  new_column = "h3string",
  h3_format = "string",
  containment = "overlap",
  buffer_scale = 1,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)
```

## Arguments

- x:

  Input data. One of:

  `duckspatial_df`

  :   A lazy spatial data frame via dbplyr.

  `sf`

  :   A spatial data frame.

  `tbl_lazy`

  :   A lazy data frame from dbplyr.

  `data.frame`

  :   A standard R data frame.

  character string

  :   A table or view name in `conn`.

  character vector

  :   A vector of values to operate on in vectorized mode (requires
      `conn = NULL`).

- resolution:

  A number specifying the resolution level of the H3 string (between 0
  and 15)

- conn:

  A connection object to a DuckDB database. If `NULL`, the function runs
  on a temporary DuckDB database.

- name:

  A character string of length one specifying the name of the table, or
  a character string of length two specifying the schema and table
  names. If `NULL` (the default), the function returns the result as an
  `sf` object

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

- containment:

  Character. Polyfill containment mode: `"overlap"` (default), `"full"`,
  `"center"`, or `"overlap_bbox"`. See the DuckDB H3 extension
  documentation for details on each mode.

- buffer_scale:

  Numeric. Line-buffer size as a multiple of one cell footprint (default
  `1`). Only used in `ddbh3_lines_to_h3()` and
  `ddbh3_lines_to_spatial()`, since a line has zero width and therefore
  no native polyfill: candidate cells are found by buffering the line,
  and the result is trimmed back to the exact intersecting set. Larger
  values are safer (slower) but never change correctness.

- new_column:

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result

- h3_format:

  Character. Output format for the H3 cell indexes stored in
  `new_column`. Either `"string"` (default) or `"bigint"`. Only used in
  `ddbh3_polygons_to_h3()` and `ddbh3_lines_to_h3()`.

## Value

One of the following, depending on the inputs:

- `tbl_lazy`:

  If `x` is not spatial.

- `duckspatial_df`:

  If `x` is spatial (e.g. an `sf` or `duckspatial_df` object).

- `TRUE` (invisibly):

  If `name` is provided, a table is created in the connection and `TRUE`
  is returned invisibly.

- vector:

  If `x` is a character vector and `conn = NULL`, the function operates
  in vectorized mode, returning a vector of the same length as `x`.

## Details

The four functions differ in the input geometry family and output
format:

- `ddbh3_polygons_to_h3()` / `ddbh3_lines_to_h3()` add a list column
  with the H3 cells intersecting each feature, as strings or `UBIGINT`

- `ddbh3_polygons_to_spatial()` / `ddbh3_lines_to_spatial()` return one
  row per (feature, intersecting cell), with the geometry replaced by
  the H3 cell hexagon boundary

Polygons are polyfilled directly with DuckDB's experimental polygon
polyfill using the `overlap` containment mode by default, so boundary
cells are included. Lines have no native polyfill: a buffer is built
around the line (sized from one cell's footprint in degrees, so it stays
latitude-correct), the buffer is polyfilled, and the candidate cells are
trimmed back to the exact intersecting set with `ST_Intersects` against
the original line.

## Examples

``` r
# \donttest{
## Load needed packages
library(duckh3)
library(duckspatial)
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE

## Setup the default connection with h3 and spatial extensions
ddbh3_default_conn(threads = 1)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpjxdHki/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.

## Build a small polygon and a small line in EPSG:4326
poly_sf <- st_as_sf(
  st_sfc(
    st_polygon(list(rbind(
      c(-0.5, -0.5), c(0.5, -0.5), c(0.5, 0.5), c(-0.5, 0.5), c(-0.5, -0.5)
    ))),
    crs = 4326
  )
)

line_sf <- st_as_sf(
  st_sfc(
    st_linestring(rbind(c(-0.5, -0.5), c(0.5, 0.5))),
    crs = 4326
  )
)

## POLYGONS TO H3 -------------

## Add a list column with the intersecting h3 strings
poly_h3_tbl <- ddbh3_polygons_to_h3(poly_sf, resolution = 4)

## POLYGONS TO SPATIAL --------

## One row per intersecting cell, geometry = cell hexagon
poly_cells_ddbs <- ddbh3_polygons_to_spatial(poly_sf, resolution = 4)

## LINES TO H3 ----------------

line_h3_tbl <- ddbh3_lines_to_h3(line_sf, resolution = 4)

## LINES TO SPATIAL -----------

line_cells_ddbs <- ddbh3_lines_to_spatial(line_sf, resolution = 4)
# }
```
