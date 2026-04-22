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
  new_column = "h3faces",
  conn = NULL,
  name = NULL,
  nested = FALSE,
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

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

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
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        faces    
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <list>   
#>  1     1     1 -43.1   16.2  B        86d02dcc7ffffff <int [1]>
#>  2     2     2  29.2   61.9  C        864221ac7ffffff <int [1]>
#>  3     3     3 -20.7   51.3  C        86a20e8f7ffffff <int [1]>
#>  4     4     4  50.9  -14.0  B        86181c6cfffffff <int [1]>
#>  5     5     5 -57.6    8.71 C        86e6cece7ffffff <int [1]>
#>  6     6     6 -56.2   21.5  B        86e69d237ffffff <int [1]>
#>  7     7     7 -33.7  -17.0  C        86c188077ffffff <int [1]>
#>  8     8     8 -32.7  -31.9  A        86c52b36fffffff <int [1]>
#>  9     9     9  -7.39  39.0  C        867b6b577ffffff <int [1]>
#> 10    10    10  10.0  -89.9  A        866d424afffffff <int [1]>
#> # ℹ more rows

## Add using mutate (unnested)
points_tbl |> 
  mutate(faces = ddbh3_get_icosahedron_faces(h3string)) |> 
  mutate(faces_unnested = unnest(faces))
#> # Source:   SQL [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        faces     faces_unnested
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <list>             <int>
#>  1     1     1 -43.1   16.2  B        86d02dcc7ffffff <int [1]>             13
#>  2     2     2  29.2   61.9  C        864221ac7ffffff <int [1]>              0
#>  3     3     3 -20.7   51.3  C        86a20e8f7ffffff <int [1]>             14
#>  4     4     4  50.9  -14.0  B        86181c6cfffffff <int [1]>              3
#>  5     5     5 -57.6    8.71 C        86e6cece7ffffff <int [1]>             18
#>  6     6     6 -56.2   21.5  B        86e69d237ffffff <int [1]>             18
#>  7     7     7 -33.7  -17.0  C        86c188077ffffff <int [1]>             13
#>  8     8     8 -32.7  -31.9  A        86c52b36fffffff <int [1]>             13
#>  9     9     9  -7.39  39.0  C        867b6b577ffffff <int [1]>              9
#> 10    10    10  10.0  -89.9  A        866d424afffffff <int [1]>             12
#> # ℹ more rows
```
