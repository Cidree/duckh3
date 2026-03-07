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

A `tbl_lazy` if `x` is not spatial, or a `duckspatial_df` if `x` is
spatial (e.g. `sf` or `duckspatial_df`). Alternatively, it creates a
table in the connection if `name` is provided, and returns `TRUE`
invisibly.

## Details

The two functions differ in the output format:

- `ddbh3_points_to_h3()` returns the H3 cell index containing each
  point, either as a string or `UBIGINT` depending on `h3_format`

- `ddbh3_points_to_spatial()` returns the H3 cell hexagon polygon
  containing each point as a spatial geometry

## Examples

``` r
if (FALSE) { # \dontrun{
## Load needed packages
library(duckh3)
library(duckspatial)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Convert to duckspatial_df
points_ddbs <- ddbs_as_spatial(points_tbl)

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
} # }
```
