# Get the average area and edge length of H3 hexagons

Get the average area or the average edge length of H3 hexagons at one or
more resolutions

## Usage

``` r
ddbh3_get_hexagon_area_avg(resolution = 8, unit = "m^2", conn = NULL)

ddbh3_get_hexagon_edge_length_avg(resolution = 8, unit = "m", conn = NULL)
```

## Arguments

- resolution:

  A vector of integers between 0 and 15 with the H3 resolutions

- unit:

  Character. Unit of the result. For `ddbh3_get_hexagon_area_avg()`, one
  of `"m^2"` (default) or `"km^2"`. For
  `ddbh3_get_hexagon_edge_length_avg()`, one of `"m"` (default) or
  `"km"`.

- conn:

  A connection object to a DuckDB database. If `NULL`, the function runs
  on a temporary DuckDB database.

## Value

A numeric vector with one value per element of `resolution`

## Details

These functions do not take H3 cells as input; they return a constant
per resolution. To get the exact area of a cell or the length of a
directed edge, use
[`ddbh3_get_area()`](https://cidree.github.io/duckh3/reference/ddbh3_get_area.md)
or
[`ddbh3_get_edge_length()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md).

They also work inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
with a column of resolutions.

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Average hexagon area at resolution 8, in km2
ddbh3_get_hexagon_area_avg(8, unit = "km^2")
#> [1] 0.7373276

## Average edge length at all resolutions
ddbh3_get_hexagon_edge_length_avg(0:15)
#>  [1] 1.281256e+06 4.830568e+05 1.825130e+05 6.897922e+04 2.607176e+04
#>  [6] 9.854091e+03 3.724533e+03 1.406476e+03 5.314140e+02 2.007861e+02
#> [11] 7.586378e+01 2.866390e+01 1.083019e+01 4.092010e+00 1.546100e+00
#> [16] 5.841686e-01

## Inside mutate
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
) |>
  ddbh3_lonlat_to_h3(resolution = 8)

points_tbl |>
  mutate(
    area = ddbh3_get_area(h3string),
    area_avg = ddbh3_get_hexagon_area_avg(ddbh3_get_resolution(h3string))
  )
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string           area area_avg
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>             <dbl>    <dbl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 702318.  737328.
#>  2     2     2  29.2   61.9  C        884221ac65fffff 759274.  737328.
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 747945.  737328.
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 758016.  737328.
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 685356.  737328.
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 612651.  737328.
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 878384.  737328.
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 769776.  737328.
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 837578.  737328.
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 726703.  737328.
#> # ℹ more rows
```
