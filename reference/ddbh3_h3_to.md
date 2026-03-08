# Convert H3 string or UBIGINT indexes to other representations

Convert H3 cell indexes stored as strings or UBIGINT into other
representations (e.g. `lon`, `lat`, `spatial`)

## Usage

``` r
ddbh3_h3_to_lon(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "lon",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_lat(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "lat",
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
  conn = NULL,
  name = NULL,
  new_column = "h3bigint",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_bigint_to_strings(
  x,
  h3 = "h3bigint",
  conn = NULL,
  name = NULL,
  new_column = "h3string",
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

## Examples

``` r
if (FALSE) { # \dontrun{
## Load needed packages
library(duckh3)
library(duckspatial)
library(dplyr)

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

## FROM UBIGINT TO STRING -----

## Add column with strings
points_strings_tbl <- ddbh3_bigint_to_strings(
  points_bigint_tbl, 
  h3 = "h3_integers"
) 

## Add using mutate
points_bigint_tbl |> 
  mutate(h3string = ddbh3_bigint_to_strings(h3_integers))

} # }
```
