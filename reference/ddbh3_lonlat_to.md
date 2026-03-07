# Convert longitude and latitude to H3 cell representations

Convert geographic coordinates (longitude and latitude) into H3 cell
representations at a specified resolution, with different output formats

## Usage

``` r
ddbh3_lonlat_to_strings(
  x,
  lon = "lon",
  lat = "lat",
  resolution = 8,
  conn = NULL,
  name = NULL,
  new_column = "h3string",
  overwrite = FALSE,
  quiet = FALSE
)

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

ddbh3_lonlat_to_bigint(
  x,
  lon = "lon",
  lat = "lat",
  resolution = 8,
  conn = NULL,
  name = NULL,
  new_column = "h3bigint",
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

The three functions differ only in the output format of the H3 cell
index:

- `ddbh3_lonlat_to_strings()` returns H3 cell indexes as strings (e.g.
  `"8928308280fffff"`)

- `ddbh3_lonlat_to_bigint()` returns H3 cell indexes as unsigned 64-bit
  integers (`UBIGINT`)

- `ddbh3_lonlat_to_spatial()` returns H3 cells as spatial hexagon
  polygons

## Examples

``` r
if (FALSE) { # \dontrun{
## TODO
} # }
```
