# Get the position of an H3 cell within its parent

Get the position of H3 cell indexes stored as strings or unsigned 64-bit
integers (`UBIGINT`) within their parent cell at a specified resolution.
The position is a zero-based index among all children of the parent
cell.

## Usage

``` r
ddbh3_get_child_pos(
  x,
  resolution = 8,
  h3 = "h3string",
  new_column = "h3child_pos",
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
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn()

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add H3 string column
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)

## Get position relative to resolution 4
ddbh3_get_child_pos(points_tbl, resolution = 4)
#> # Source:   table<temp_view_9cc038af_ec72_4788_8e17_2bdecc80b9de> [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        h3child_pos
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>               <int64>
#>  1     1     1 -43.1   16.2  B        86d02dcc7ffffff          21
#>  2     2     2  29.2   61.9  C        864221ac7ffffff          21
#>  3     3     3 -20.7   51.3  C        86a20e8f7ffffff          27
#>  4     4     4  50.9  -14.0  B        86181c6cfffffff          22
#>  5     5     5 -57.6    8.71 C        86e6cece7ffffff          25
#>  6     6     6 -56.2   21.5  B        86e69d237ffffff           6
#>  7     7     7 -33.7  -17.0  C        86c188077ffffff          13
#>  8     8     8 -32.7  -31.9  A        86c52b36fffffff          40
#>  9     9     9  -7.39  39.0  C        867b6b577ffffff          41
#> 10    10    10  10.0  -89.9  A        866d424afffffff          19
#> # ℹ more rows

## Add using mutate
points_tbl |> 
  mutate(child_pos = ddbh3_get_child_pos(h3string, 4))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        child_pos
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>             <int64>
#>  1     1     1 -43.1   16.2  B        86d02dcc7ffffff        21
#>  2     2     2  29.2   61.9  C        864221ac7ffffff        21
#>  3     3     3 -20.7   51.3  C        86a20e8f7ffffff        27
#>  4     4     4  50.9  -14.0  B        86181c6cfffffff        22
#>  5     5     5 -57.6    8.71 C        86e6cece7ffffff        25
#>  6     6     6 -56.2   21.5  B        86e69d237ffffff         6
#>  7     7     7 -33.7  -17.0  C        86c188077ffffff        13
#>  8     8     8 -32.7  -31.9  A        86c52b36fffffff        40
#>  9     9     9  -7.39  39.0  C        867b6b577ffffff        41
#> 10    10    10  10.0  -89.9  A        866d424afffffff        19
#> # ℹ more rows
```
