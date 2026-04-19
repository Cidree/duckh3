# Convert spatial points to H3 cell representations

Convert spatial point geometries into H3 cell representations at a
specified resolution. Input must be an `duckspatial_df`, `sf`, or table
with point geometries

## Usage

``` r
ddbh3_points_to_spatial(
  x,
  resolution,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_points_to_h3(
  x,
  resolution,
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

  Character. Output format for the H3 cell index. Either `"string"`
  (default) or `"bigint"`. Only used in `ddbh3_points_to_h3()`.

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

The two functions differ in the output format:

- `ddbh3_points_to_h3()` returns the H3 cell index containing each
  point, either as a string or `UBIGINT` depending on `h3_format`

- `ddbh3_points_to_spatial()` returns the H3 cell hexagon polygon
  containing each point as a spatial geometry

## Examples

``` r
## Load needed packages
library(duckh3)
library(duckspatial)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Convert to duckspatial_df
points_ddbs <- ddbs_as_points(points_tbl)

## TO H3 strings/ubigint ------------

## Add column with h3 strings at resolution 8
points_strings_ddbs <- ddbh3_points_to_h3(points_ddbs, 8)

## Add column with h3 ubigint at resolution 10
points_bigint_ddbs <- ddbh3_points_to_h3(
  points_ddbs, 
  resolution = 8,
  new_column = "h3bigint",
  h3_format = "bigint"
)

## TO SPATIAL -----------------

## Convert from POINTS to H3 POLYGONS of res 8
polygons_8_ddbs <- ddbh3_points_to_spatial(points_ddbs, 8)

## Collect as sf
polygons_8_sf <- ddbs_collect(polygons_8_ddbs)
```
