# Convert H3 cell indexes to vertex representations

Convert H3 cell indexes stored as strings or unsigned 64-bit integers
(`UBIGINT`) to their vertex representations

## Usage

``` r
ddbh3_h3_to_vertex(
  x,
  h3 = "h3string",
  n = 0,
  conn = NULL,
  name = NULL,
  new_column = "h3vertex",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lon(
  x,
  h3vertex = "h3vertex",
  conn = NULL,
  name = NULL,
  new_column = "lon_vertex",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lat(
  x,
  h3vertex = "h3vertex",
  conn = NULL,
  name = NULL,
  new_column = "lon_vertex",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_vertexes(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "h3vertex",
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

  Input spatial data. Can be:

  - A `duckspatial_df` object (lazy spatial data frame via dbplyr)

  - An `sf` object

  - A `tbl_lazy` from dbplyr

  - A character string naming a table/view in `conn`

  Data is returned from this object.

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- n:

  Integer. Vertex number to retrieve. Must be in the range 0–5 for
  hexagons and 0–4 for pentagons. Only used in `ddbh3_h3_to_vertex()`.

- conn:

  A connection object to a DuckDB database. If `NULL`, the function runs
  on a temporary DuckDB database.

- name:

  A character string of length one specifying the name of the table, or
  a character string of length two specifying the schema and table
  names. If `NULL` (the default), the function returns the result as an
  `sf` object

- new_column:

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result

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

A `tbl_lazy` if `x` is not spatial, or a `duckspatial_df` if `x` is
spatial (e.g. `sf` or `duckspatial_df`). Alternatively, it creates a
table in the connection if `name` is provided, and returns `TRUE`
invisibly.

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
## TODO
} # }
```
