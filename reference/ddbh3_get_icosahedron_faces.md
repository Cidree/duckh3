# Get the icosahedron faces of H3 cell indexes

Get the icosahedron faces intersected by H3 cell indexes stored as
strings or unsigned 64-bit integers (`UBIGINT`). Each H3 cell maps onto
one or more of the 20 faces of the underlying icosahedron used to
construct the H3 grid.

## Usage

``` r
ddbh3_get_icosahedron_faces(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "h3faces",
  nested = FALSE,
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

- nested:

  Logical. If `TRUE`, children are returned as a nested list column (one
  row per parent cell). If `FALSE` (default), the result is unnested so
  each child cell occupies its own row.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

## Value

A `tbl_lazy` if `x` is not spatial, or a `duckspatial_df` if `x` is
spatial (e.g. `sf` or `duckspatial_df`). Alternatively, it creates a
table in the connection if `name` is provided, and returns `TRUE`
invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
## Load needed packages
library(duckh3)
library(dplyr)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add H3 string column
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)

## Get faces (unnested)
faces_tbl <- ddbh3_get_icosahedron_faces(points_tbl)

## Get faces (nested)
faces_nested_tbl <- ddbh3_get_icosahedron_faces(points_tbl, nested = TRUE)

## Add using mutate (nested)
points_tbl |> 
  mutate(faces = ddbh3_get_icosahedron_faces(h3string))

## Add using mutate (unnested)
points_tbl |> 
  mutate(faces = ddbh3_get_icosahedron_faces(h3string)) |> 
  mutate(faces_unnested = unnest(faces))
} # }
```
