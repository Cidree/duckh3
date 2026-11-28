# Get the area of H3 cells

Get the exact area of H3 cell indexes stored as strings or unsigned
64-bit integers

## Usage

``` r
ddbh3_get_area(
  x,
  h3 = "h3string",
  unit = "m^2",
  new_column = "h3area",
  conn = NULL,
  name = NULL,
  mode = NULL,
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

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- unit:

  Character. Unit of the area. One of `"m^2"` (default), `"km^2"` or
  `"rads^2"`.

- new_column:

  Name of the new column to create on the input data. Defaults to
  `"h3area"`.

- conn:

  A connection object to a DuckDB database. If `NULL`, the function runs
  on a temporary DuckDB database.

- name:

  A character string of length one specifying the name of the table, or
  a character string of length two specifying the schema and table
  names. If `NULL` (the default), the function returns the result as an
  `sf` object

- mode:

  Character. Controls the return type. Options:

  - `"duckspatial"` (default): Lazy spatial data frame backed by
    dbplyr/DuckDB

  - `"sf"`: Eagerly collected sf object (uses memory)

  Can be set globally via
  [`ddbs_options`](https://cidree.github.io/duckspatial/reference/ddbs_options.html)`(mode = "...")`
  or per-function via this argument. Per-function overrides global
  setting. It only applies when the output has a geometry column, and is
  ignored otherwise.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

## Value

One of the following, depending on the inputs:

- `tbl_lazy`:

  If the output has no geometry, i.e. `x` is not spatial and the
  function adds a column. `mode` is ignored in this case.

- `duckspatial_df`:

  If the output has geometry (`x` is spatial, e.g. an `sf` or
  `duckspatial_df` object, or the function builds geometries, as
  `*_to_spatial()` and
  [`ddbh3_h3_to_points()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  do) and `mode = "duckspatial"` (default).

- `sf`:

  If the output has geometry and `mode = "sf"`.

- `TRUE` (invisibly):

  If `name` is provided, a table is created in the connection and `TRUE`
  is returned invisibly.

- vector:

  If `x` is a character vector and `conn = NULL`, the function operates
  in vectorized mode, returning a vector of the same length as `x`.

## Details

The area is computed for each individual cell, so it differs from the
average cell area at a resolution returned by
[`ddbh3_get_hexagon_area_avg()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hexagon_avg.md).
Cells of the same resolution have different areas depending on their
location on the globe.

## See also

[`ddbh3_get_hexagon_area_avg()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hexagon_avg.md),
[`ddbh3_get_edge_length()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add h3 strings
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)

## Area of the cells in square meters
ddbh3_get_area(points_tbl)
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string         h3area
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>             <dbl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 702318.
#>  2     2     2  29.2   61.9  C        884221ac65fffff 759274.
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 747945.
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 758016.
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 685356.
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 612651.
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 878384.
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 769776.
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 837578.
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 726703.
#> # ℹ more rows

## Area in square kilometers
ddbh3_get_area(points_tbl, unit = "km^2")
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        h3area
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>            <dbl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff  0.702
#>  2     2     2  29.2   61.9  C        884221ac65fffff  0.759
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff  0.748
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff  0.758
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff  0.685
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff  0.613
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff  0.878
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff  0.770
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff  0.838
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff  0.727
#> # ℹ more rows

## Inside mutate
points_tbl |>
  mutate(area = ddbh3_get_area(h3string, 'km^2'))
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string         area
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <dbl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 0.702
#>  2     2     2  29.2   61.9  C        884221ac65fffff 0.759
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 0.748
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 0.758
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 0.685
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 0.613
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 0.878
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 0.770
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 0.838
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 0.727
#> # ℹ more rows

## Vectorized mode
ddbh3_get_area("8a1fb46622dffff")
#> [1] 13407.83
```
