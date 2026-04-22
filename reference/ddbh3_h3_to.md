# Convert H3 string or UBIGINT indexes to other representations

Convert H3 cell indexes stored as strings or UBIGINT into other
representations (e.g. `lon`, `lat`, `spatial`)

## Usage

``` r
ddbh3_h3_to_lon(
  x,
  h3 = "h3string",
  new_column = "lon",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_lat(
  x,
  h3 = "h3string",
  new_column = "lat",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_spatial(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_strings_to_bigint(
  x,
  h3 = "h3string",
  new_column = "h3bigint",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_bigint_to_strings(
  x,
  h3 = "h3bigint",
  new_column = "h3string",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_points(
  x,
  h3 = "h3string",
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

## Details

The four functions differ only in the output format:

- `ddbh3_h3_to_spatial()` converts H3 indexes to spatial hexagon
  polygons

- `ddbh3_h3_to_lon()` extracts the longitude of the H3 cell centroid

- `ddbh3_h3_to_lat()` extracts the latitude of the H3 cell centroid

- `ddbh3_strings_to_bigint()` converts H3 indexes to unsigned 64-bit
  integers (`UBIGINT`)

- `ddbh3_bigint_to_strings()` converts H3 indexes to strings (e.g.
  `"8928308280fffff"`)

- `ddbh3_h3_to_points()` converts H3 indexes to spatial points located
  at the centroid of the H3 cell

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

## Add H3 string column
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6) |> 
  select(-lon, -lat)

## TO LON/LAT ------------

## Add longitude and latitude of the H3 string
points_coords_tbl <- points_tbl |> 
  ddbh3_h3_to_lat() |> 
  ddbh3_h3_to_lon()

## Add lon/lat with other names
points_coords_2_tbl <- points_tbl |> 
  ddbh3_h3_to_lat(new_column = "latitude") |> 
  ddbh3_h3_to_lon(new_column = "longitude")

## Add using mutate
points_tbl |> 
  mutate(
    lon = ddbh3_h3_to_lon(h3string),
    lat = ddbh3_h3_to_lat(h3string)
  )
#> # Source:   SQL [?? x 6]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id category h3string           lon    lat
#>    <int> <int> <chr>    <chr>            <dbl>  <dbl>
#>  1     1     1 B        86d02dcc7ffffff  16.2  -43.1 
#>  2     2     2 C        864221ac7ffffff  62.0   29.2 
#>  3     3     3 C        86a20e8f7ffffff  51.3  -20.7 
#>  4     4     4 B        86181c6cfffffff -14.1   50.9 
#>  5     5     5 C        86e6cece7ffffff   8.71 -57.6 
#>  6     6     6 B        86e69d237ffffff  21.5  -56.2 
#>  7     7     7 C        86c188077ffffff -17.0  -33.7 
#>  8     8     8 A        86c52b36fffffff -31.9  -32.7 
#>  9     9     9 C        867b6b577ffffff  39.0   -7.39
#> 10    10    10 A        866d424afffffff -89.9   10.0 
#> # ℹ more rows

## TO SPATIAL -----------------

## Convert h3 strings to spatial polygons
points_ddbs <- ddbh3_h3_to_spatial(points_tbl)

## Collect as sf
points_sf <- ddbs_collect(points_ddbs)

## FROM STRING TO UBIGINT -----

## Add ubigint, and remove strings
points_bigint_tbl <- ddbh3_strings_to_bigint(
  points_tbl, 
  new_column = "h3_integers"
) |> 
  select(-h3string)

## Add using mutate
points_tbl |> 
  mutate(h3int = ddbh3_strings_to_bigint(h3string))
#> # Source:   SQL [?? x 5]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id category h3string          h3int
#>    <int> <int> <chr>    <chr>           <int64>
#>  1     1     1 B        86d02dcc7ffffff    6e17
#>  2     2     2 C        864221ac7ffffff    6e17
#>  3     3     3 C        86a20e8f7ffffff    6e17
#>  4     4     4 B        86181c6cfffffff    6e17
#>  5     5     5 C        86e6cece7ffffff    6e17
#>  6     6     6 B        86e69d237ffffff    6e17
#>  7     7     7 C        86c188077ffffff    6e17
#>  8     8     8 A        86c52b36fffffff    6e17
#>  9     9     9 C        867b6b577ffffff    6e17
#> 10    10    10 A        866d424afffffff    6e17
#> # ℹ more rows

## FROM UBIGINT TO STRING -----

## Add column with strings
points_strings_tbl <- ddbh3_bigint_to_strings(
  points_bigint_tbl, 
  h3 = "h3_integers"
) 

## Add using mutate
points_bigint_tbl |> 
  mutate(h3string = ddbh3_bigint_to_strings(h3_integers))
#> # Source:   SQL [?? x 5]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id category h3_integers h3string       
#>    <int> <int> <chr>        <int64> <chr>          
#>  1     1     1 B               6e17 86d02dcc7ffffff
#>  2     2     2 C               6e17 864221ac7ffffff
#>  3     3     3 C               6e17 86a20e8f7ffffff
#>  4     4     4 B               6e17 86181c6cfffffff
#>  5     5     5 C               6e17 86e6cece7ffffff
#>  6     6     6 B               6e17 86e69d237ffffff
#>  7     7     7 C               6e17 86c188077ffffff
#>  8     8     8 A               6e17 86c52b36fffffff
#>  9     9     9 C               6e17 867b6b577ffffff
#> 10    10    10 A               6e17 866d424afffffff
#> # ℹ more rows
```
