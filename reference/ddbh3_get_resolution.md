# Get the resolution of H3 cell indexes

Get the resolution of H3 cell indexes stored as strings or unsigned
64-bit integers (`UBIGINT`) from an existing column.

## Usage

``` r
ddbh3_get_resolution(
  x,
  h3 = "h3string",
  new_column = "h3resolution",
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

## Examples

``` r
## Load needed packages
library(duckh3)
library(duckspatial)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add h3 strings
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 10)

## Convert to duckspatial_df
points_ddbs <- ddbs_as_points(points_tbl)
#> Warning: Could not auto-detect CRS for <tbl_duckdb_connection> object.
#> ℹ The object may not be a view created from a spatial file.
#> ℹ Use `as_duckspatial_df(x, crs = ...)` to set CRS explicitly.

## Get resolution of the h3 strings
ddbh3_get_resolution(points_tbl)
#> # Source:   table<temp_view_c2d7c9bd_db02_4e0d_8a8e_6af5746da554> [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        h3resolution
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>                  <int>
#>  1     1     1 -43.1   16.2  B        8ad02dcc1947fff           10
#>  2     2     2  29.2   61.9  C        8a4221ac6507fff           10
#>  3     3     3 -20.7   51.3  C        8aa20e8f6997fff           10
#>  4     4     4  50.9  -14.0  B        8a181c6c824ffff           10
#>  5     5     5 -57.6    8.71 C        8ae6cece5d37fff           10
#>  6     6     6 -56.2   21.5  B        8ae69d233d17fff           10
#>  7     7     7 -33.7  -17.0  C        8ac188075167fff           10
#>  8     8     8 -32.7  -31.9  A        8ac52b36c52ffff           10
#>  9     9     9  -7.39  39.0  C        8a7b6b570027fff           10
#> 10    10    10  10.0  -89.9  A        8a6d424ae00ffff           10
#> # ℹ more rows
ddbh3_get_resolution(points_ddbs, new_column = "res")
#> # A duckspatial lazy spatial table
#> # ● CRS: EPSG:4326 
#> # ● Geometry column: geometry 
#> # ● Geometry type: POINT 
#> # ● Bounding box: xmin: -97.934 ymin: -59.987 xmax: 94.802 ymax: 59.805 
#> # Data backed by DuckDB (dbplyr lazy evaluation)
#> # Use ddbs_collect() or st_as_sf() to materialize to sf
#> #
#> # Source:   table<temp_view_54fd8ddb_4c45_447d_a499_5dc9699ef827> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string          res geometry            
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <int> <wk_wkb>            
#>  1     1     1 -43.1   16.2  B        8ad02dcc1947fff    10 <POINT (16.19255 -4…
#>  2     2     2  29.2   61.9  C        8a4221ac6507fff    10 <POINT (61.93297 29…
#>  3     3     3 -20.7   51.3  C        8aa20e8f6997fff    10 <POINT (51.25918 -2…
#>  4     4     4  50.9  -14.0  B        8a181c6c824ffff    10 <POINT (-14.04381 5…
#>  5     5     5 -57.6    8.71 C        8ae6cece5d37fff    10 <POINT (8.706529 -5…
#>  6     6     6 -56.2   21.5  B        8ae69d233d17fff    10 <POINT (21.49123 -5…
#>  7     7     7 -33.7  -17.0  C        8ac188075167fff    10 <POINT (-17.00882 -…
#>  8     8     8 -32.7  -31.9  A        8ac52b36c52ffff    10 <POINT (-31.87905 -…
#>  9     9     9  -7.39  39.0  C        8a7b6b570027fff    10 <POINT (39.03139 -7…
#> 10    10    10  10.0  -89.9  A        8a6d424ae00ffff    10 <POINT (-89.91508 1…
#> # ℹ more rows

## Add using mutate
points_tbl |> 
  mutate(res = ddbh3_get_resolution(h3string))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string          res
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <int>
#>  1     1     1 -43.1   16.2  B        8ad02dcc1947fff    10
#>  2     2     2  29.2   61.9  C        8a4221ac6507fff    10
#>  3     3     3 -20.7   51.3  C        8aa20e8f6997fff    10
#>  4     4     4  50.9  -14.0  B        8a181c6c824ffff    10
#>  5     5     5 -57.6    8.71 C        8ae6cece5d37fff    10
#>  6     6     6 -56.2   21.5  B        8ae69d233d17fff    10
#>  7     7     7 -33.7  -17.0  C        8ac188075167fff    10
#>  8     8     8 -32.7  -31.9  A        8ac52b36c52ffff    10
#>  9     9     9  -7.39  39.0  C        8a7b6b570027fff    10
#> 10    10    10  10.0  -89.9  A        8a6d424ae00ffff    10
#> # ℹ more rows
```
