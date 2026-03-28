# Convert H3 cell indexes to vertex representations

Convert H3 cell indexes stored as strings or unsigned 64-bit integers
(`UBIGINT`) to their vertex representations

## Usage

``` r
ddbh3_h3_to_vertex(
  x,
  n = 0,
  h3 = "h3string",
  new_column = "h3vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lon(
  x,
  h3vertex = "h3vertex",
  new_column = "lon_vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lat(
  x,
  h3vertex = "h3vertex",
  new_column = "lat_vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_vertexes(
  x,
  h3 = "h3string",
  new_column = "h3vertex",
  conn = NULL,
  name = NULL,
  nested = FALSE,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_spatial(
  x,
  h3vertex = "h3vertex",
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

- n:

  Integer. Vertex number to retrieve. Must be in the range 0–5 for
  hexagons and 0–4 for pentagons. Only used in `ddbh3_h3_to_vertex()`.

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- new_column:

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result

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

- h3vertex:

  Name of the column containing H3 vertex strings. Defaults to
  `"h3vertex"`

- nested:

  Logical. If `TRUE`, children are returned as a nested list column (one
  row per parent cell). If `FALSE` (default), the result is unnested so
  each child cell occupies its own row.

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

The functions cover the full vertex workflow:

- `ddbh3_h3_to_vertex()` returns a single vertex of an H3 cell,
  identified by its vertex number `n` (0–5 for hexagons, 0–4 for
  pentagons), as an H3 vertex string

- `ddbh3_h3_to_vertexes()` returns all vertices of an H3 cell as H3
  vertex strings — either nested (one row per cell) or unnested (one row
  per vertex) depending on `nested`

- `ddbh3_vertex_to_lat()` returns the latitude of an H3 vertex string

- `ddbh3_vertex_to_lon()` returns the longitude of an H3 vertex string

- `ddbh3_vertex_to_spatial()` converts H3 vertex strings to spatial
  point geometries. If the input column is nested, vertices are
  automatically unnested and aggregated into a `MULTIPOINT` geometry per
  cell

## Examples

``` r
if (FALSE) { # \dontrun{
## Load needed packages
library(duckh3)
library(duckspatial)
library(dplyr)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add h3 strings
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)

## TO VERTEX ---------------

## Add second vertex
vertex_2_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 2)

## Add add vertexes (unnested)
vertexes_tbl <- ddbh3_h3_to_vertexes(points_tbl)

## Add add vertexes (nested)
vertexes_nested_tbl <- ddbh3_h3_to_vertexes(points_tbl, nested = TRUE)

## Add some vertexes with with mutate
points_tbl |> 
  mutate(
    v1 = ddbh3_h3_to_vertex(h3string, 1),
    v3 = ddbh3_h3_to_vertex(h3string, 3)
  )

## VERTEX TO LON/LAT ------

## Add coords
coords_vertex_tbl <- vertex_2_tbl |> 
  ddbh3_vertex_to_lon(new_column = "lon_v2") |> 
  ddbh3_vertex_to_lat(new_column = "lat_v2")

## Add coords in mutate
vertex_2_tbl |> 
  mutate(
    lon_v2 = ddbh3_vertex_to_lon(h3vertex),
    lat_v2 = ddbh3_vertex_to_lat(h3vertex)
  )

## VERTEX TO SPATIAL ------

## Convert unnested vertexes (returns POINTS)
ddbh3_h3_to_vertexes(points_tbl) |> 
  ddbh3_vertex_to_spatial()


## Convert nested vertexes (returns MULTIPOINTS)
ddbh3_h3_to_vertexes(points_tbl, nested = TRUE) |> 
  ddbh3_vertex_to_spatial()
} # }
```
