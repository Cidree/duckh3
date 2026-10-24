# Get H3 grid neighborhoods (disks, rings, and distances)

Functions to generate surrounding H3 neighborhood cells based on
step-by-step grid distances (k-rings and hollow rings).

## Usage

``` r
ddbh3_grid_disk(
  x,
  k = 1,
  h3 = "h3string",
  new_column = "h3neighbors",
  conn = NULL,
  name = NULL,
  mode = NULL,
  nested = FALSE,
  overwrite = FALSE,
  safe = FALSE,
  quiet = FALSE
)

ddbh3_grid_disk_distances(
  x,
  k = 1,
  h3 = "h3string",
  new_column = "h3neighbors",
  conn = NULL,
  name = NULL,
  mode = NULL,
  nested = FALSE,
  overwrite = FALSE,
  safe = TRUE,
  quiet = FALSE
)

ddbh3_grid_ring(
  x,
  k = 1,
  h3 = "h3string",
  new_column = "h3neighbors",
  conn = NULL,
  name = NULL,
  mode = NULL,
  nested = FALSE,
  overwrite = FALSE,
  safe = FALSE,
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

- k:

  Integer. The grid distance (number of neighbor hops). Defaults to `1`.

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

- mode:

  Character. Controls the return type. Options:

  - `"duckspatial"` (default): Lazy spatial data frame backed by
    dbplyr/DuckDB

  - `"sf"`: Eagerly collected sf object (uses memory)

  Can be set globally via
  [`ddbs_options`](https://cidree.github.io/duckspatial/reference/ddbs_options.html)`(mode = "...")`
  or per-function via this argument. Per-function overrides global
  setting.

- nested:

  Logical. If `TRUE`, children are returned as a nested list column (one
  row per parent cell). If `FALSE` (default), the result is unnested so
  each child cell occupies its own row.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- safe:

  A logical value. If `TRUE` (default), uses safe algorithms that
  correctly handle pentagonal distortion. If `FALSE`, uses faster unsafe
  algorithms which may fail or produce incorrect results near pentagons.

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

## Details

These functions differ in how they traverse and select neighborhood
cells:

- **`ddbh3_grid_disk()`**: Returns all H3 cells within a grid distance
  `k` from the origin cell (inclusive of all rings from distance 0 up to
  `k`).

- **`dbh3_grid_disk_distances()`**: Similar to grid disk, but leverages
  the underlying distance-aware function variant to extract neighborhood
  cells.

- **`ddbh3_grid_ring()`**: Returns only the exact hollow ring of H3
  cells located at the specific distance `k` from the origin cell,
  excluding all inner cells.

## Examples

``` r
library(duckh3)
library(dplyr)

ddbh3_default_conn(threads = 1)
points_tbl <- read.csv(system.file("extdata/example_pts.csv", package = "duckh3"))
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)

# Get grid disk (k = 1)
ddbh3_grid_disk(points_tbl, k = 1)
#> # A query:  ?? x 7
#> # Database: DuckDB 1.5.6 [unknown@Linux 6.17.0-1022-azure:R 4.6.1/:memory:]
#>        X    id   lat   lon category h3string        h3neighbors    
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>          
#>  1     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dcc7ffffff
#>  2     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dcf7ffffff
#>  3     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dcd7ffffff
#>  4     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dcdfffffff
#>  5     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dccfffffff
#>  6     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dcefffffff
#>  7     1     1 -43.1  16.2 B        86d02dcc7ffffff 86d02dce7ffffff
#>  8     2     2  29.2  61.9 C        864221ac7ffffff 864221ac7ffffff
#>  9     2     2  29.2  61.9 C        864221ac7ffffff 864221af7ffffff
#> 10     2     2  29.2  61.9 C        864221ac7ffffff 864221ad7ffffff
#> # ℹ more rows
```
