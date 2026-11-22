# Get the great circle distance between two points

Get the great circle (haversine) distance between two points given by
their longitude and latitude

## Usage

``` r
ddbh3_great_circle_distance(
  x,
  lon_start,
  lat_start,
  lon_end,
  lat_end,
  unit = "m",
  new_column = "distance",
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

- lon_start, lat_start:

  The names of the columns in `x` containing the longitude and latitude
  of the start points

- lon_end, lat_end:

  The names of the columns in `x` containing the longitude and latitude
  of the end points

- unit:

  Character. Unit of the distance. One of `"m"` (default), `"km"` or
  `"rads"`.

- new_column:

  Name of the new column to create on the input data. Defaults to
  `"distance"`.

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

## Two pairs of points
pairs_tbl <- data.frame(
  lon1 = c(-3.70, -8.54),
  lat1 = c(40.42, 42.88),
  lon2 = c(2.17, -8.41),
  lat2 = c(41.39, 43.36)
)

## Distance in kilometers
ddbh3_great_circle_distance(
  pairs_tbl,
  lon_start = "lon1",
  lat_start = "lat1",
  lon_end = "lon2",
  lat_end = "lat2",
  unit = "km"
)
#> # A query:  ?? x 5
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    lon1  lat1  lon2  lat2 distance
#>   <dbl> <dbl> <dbl> <dbl>    <dbl>
#> 1 -3.7   40.4  2.17  41.4    505. 
#> 2 -8.54  42.9 -8.41  43.4     54.4

## Inside mutate
pairs_tbl |>
  ddbh3_great_circle_distance("lon1", "lat1", "lon2", "lat2") |>
  mutate(dist_km = ddbh3_great_circle_distance(lon1, lat1, lon2, lat2, 'km'))
#> # A query:  ?? x 6
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    lon1  lat1  lon2  lat2 distance dist_km
#>   <dbl> <dbl> <dbl> <dbl>    <dbl>   <dbl>
#> 1 -3.7   40.4  2.17  41.4  504864.   505. 
#> 2 -8.54  42.9 -8.41  43.4   54407.    54.4
```
