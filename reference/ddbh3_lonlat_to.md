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
  conn = NULL,
  name = NULL,
  new_column = "h3string",
  h3_format = "string",
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

A `tbl_lazy` if `x` is not spatial, or a `duckspatial_df` if `x` is
spatial (e.g. `sf` or `duckspatial_df`). Alternatively, it creates a
table in the connection if `name` is provided, and returns `TRUE`
invisibly.

## Details

The three functions differ only in the output format of the H3 cell
index:

- `ddbh3_lonlat_to_h3()` returns H3 cell indexes as strings (e.g.
  `"8928308280fffff"`) or as unsigned 64-bit integers (`UBIGINT`)

- `ddbh3_lonlat_to_spatial()` returns H3 cells as spatial hexagon
  polygons

## Examples

``` r
if (FALSE) { # \dontrun{
## Load needed packages
library(duckdb)
library(duckh3)
library(duckspatial)
library(dplyr)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Create a connection with spatial and h3 extensions
conn <- ddbh3_create_conn()

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


## Create a new table in the connection
ddbh3_lonlat_to_h3(
  points_tbl,
  conn = conn,
  name = "points_strings_8"
)

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

## Open the created table lazily
as_duckspatial_df("points_strings_spatial", conn)

## Read it in memory as an sf object
ddbs_read_table(conn, "points_strings_spatial")

} # }
```
