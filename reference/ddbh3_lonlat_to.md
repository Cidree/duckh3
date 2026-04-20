# Convert longitude and latitude to H3 cell representations

Convert geographic coordinates (longitude and latitude) into H3 cell
representations at a specified resolution, with different output formats

## Usage

``` r
ddbh3_lonlat_to_spatial(
  x,
  lon = "lon",
  lat = "lat",
  resolution = 8,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_lonlat_to_h3(
  x,
  lon = "lon",
  lat = "lat",
  resolution = 8,
  new_column = "h3string",
  h3_format = "string",
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

- lon:

  The name of a column in `x` containing the longitude

- lat:

  The name of a column in `x` containing the latitude

- resolution:

  A number specifying the resolution level of the H3 string (between 0
  and 15)

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

- new_column:

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result

- h3_format:

  Character. The format of the H3 cell index: `string` or `bigint`

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

The three functions differ only in the output format of the H3 cell
index:

- `ddbh3_lonlat_to_h3()` returns H3 cell indexes as strings (e.g.
  `"8928308280fffff"`) or as unsigned 64-bit integers (`UBIGINT`)

- `ddbh3_lonlat_to_spatial()` returns H3 cells as spatial hexagon
  polygons

## Examples

``` r
## Load needed packages
library(duckdb)
#> Loading required package: DBI
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

## Create a connection with spatial and h3 extensions
conn <- ddbh3_create_conn(threads = 1)

## TO H3 ------------

## Add h3 strings as a new column (res 5)
points_strings_5_tbl <- ddbh3_lonlat_to_h3(
  points_tbl,
  resolution = 5
)

## Add h3 UBIGINT as a new column (res 8 by default)
points_bigint_8_tbl <- ddbh3_lonlat_to_h3(
  points_tbl,
  new_column = "h3bigint",
  h3_format  = "bigint"
)

## If column names are different from lon/lat:
points_renamed <- rename(points_tbl, long = lon, lati = lat)

ddbh3_lonlat_to_h3(
  points_renamed,
  lon = "long",
  lat = "lati",
  resolution = 10
)
#> # Source:   table<temp_view_665050bb_6145_41c1_beb4_af5177bbb7d1> [?? x 6]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id   lati   long category h3string       
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>          
#>  1     1     1 -43.1   16.2  B        8ad02dcc1947fff
#>  2     2     2  29.2   61.9  C        8a4221ac6507fff
#>  3     3     3 -20.7   51.3  C        8aa20e8f6997fff
#>  4     4     4  50.9  -14.0  B        8a181c6c824ffff
#>  5     5     5 -57.6    8.71 C        8ae6cece5d37fff
#>  6     6     6 -56.2   21.5  B        8ae69d233d17fff
#>  7     7     7 -33.7  -17.0  C        8ac188075167fff
#>  8     8     8 -32.7  -31.9  A        8ac52b36c52ffff
#>  9     9     9  -7.39  39.0  C        8a7b6b570027fff
#> 10    10    10  10.0  -89.9  A        8a6d424ae00ffff
#> # ℹ more rows


## Create a new table in the connection
ddbh3_lonlat_to_h3(
  points_tbl,
  conn = conn,
  name = "points_strings_8"
)
#> ✔ Query successful

## Open the created table lazily
points_lazy <- dplyr::tbl(conn, "points_strings_8")

## Read it in memory
points_eager <- dbReadTable(conn, "points_strings_8")


## TO SPATIAL -----------

## Add h3 strings as a new column (res 5)
points_5_ddbs <- ddbh3_lonlat_to_spatial(
  points_tbl,
  resolution = 5
)

## Create a new table in the connection
ddbh3_lonlat_to_spatial(
  points_tbl,
  conn = conn,
  name = "points_strings_spatial"
)
#> ✔ Query successful

## Open the created table lazily
as_duckspatial_df("points_strings_spatial", conn)
#> # A duckspatial lazy spatial table
#> # ● CRS: EPSG:4326 
#> # ● Geometry column: geometry 
#> # ● Geometry type: POLYGON 
#> # ● Bounding box: xmin: -97.944 ymin: -59.99 xmax: 94.807 ymax: 59.812 
#> # Data backed by DuckDB (dbplyr lazy evaluation)
#> # Use ddbs_collect() or st_as_sf() to materialize to sf
#> #
#> # Source:   table<points_strings_spatial> [?? x 6]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category geometry                                  
#>    <int> <int>  <dbl>  <dbl> <chr>    <wk_wkb>                                  
#>  1     1     1 -43.1   16.2  B        <POLYGON ((16.18579 -43.06821, 16.18338 -…
#>  2     2     2  29.2   61.9  C        <POLYGON ((61.93085 29.18522, 61.93232 29…
#>  3     3     3 -20.7   51.3  C        <POLYGON ((51.25962 -20.67759, 51.2582 -2…
#>  4     4     4  50.9  -14.0  B        <POLYGON ((-14.04109 50.85767, -14.04793 …
#>  5     5     5 -57.6    8.71 C        <POLYGON ((8.706577 -57.6205, 8.709258 -5…
#>  6     6     6 -56.2   21.5  B        <POLYGON ((21.49239 -56.21158, 21.49306 -…
#>  7     7     7 -33.7  -17.0  C        <POLYGON ((-17.01467 -33.70043, -17.01892…
#>  8     8     8 -32.7  -31.9  A        <POLYGON ((-31.88143 -32.71693, -31.88588…
#>  9     9     9  -7.39  39.0  C        <POLYGON ((39.03433 -7.391451, 39.03606 -…
#> 10    10    10  10.0  -89.9  A        <POLYGON ((-89.91591 10.01776, -89.92006 …
#> # ℹ more rows

## Read it in memory as an sf object
ddbs_read_table(conn, "points_strings_spatial")
#> ✔ table points_strings_spatial successfully imported.
#> Simple feature collection with 100 features and 5 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -97.94382 ymin: -59.99012 xmax: 94.80651 ymax: 59.81162
#> Geodetic CRS:  WGS 84
#> First 10 features:
#>     X id        lat        lon category                       geometry
#> 1   1  1 -43.069252  16.192548        B POLYGON ((16.18579 -43.0682...
#> 2   2  2  29.185117  61.932969        C POLYGON ((61.93085 29.18522...
#> 3   3  3 -20.682592  51.259176        C POLYGON ((51.25962 -20.6775...
#> 4   4  4  50.856814 -14.043806        B POLYGON ((-14.04109 50.8576...
#> 5   5  5 -57.620368   8.706529        C POLYGON ((8.706577 -57.6205...
#> 6   6  6 -56.210542  21.491229        B POLYGON ((21.49239 -56.2115...
#> 7   7  7 -33.702164 -17.008820        C POLYGON ((-17.01467 -33.700...
#> 8   8  8 -32.718974 -31.879051        A POLYGON ((-31.88143 -32.716...
#> 9   9  9  -7.388245  39.031393        C POLYGON ((39.03433 -7.39145...
#> 10 10 10  10.011989 -89.915075        A POLYGON ((-89.91591 10.0177...
```
