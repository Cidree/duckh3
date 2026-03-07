# Convert H3 bigint indexes to other representations

Convert H3 cell indexes stored as unsigned 64-bit integers (`UBIGINT`)
into other formats (e.g. H3 strings)

## Usage

``` r
ddbh3_bigint_to_strings(
  x,
  h3bigint = "h3bigint",
  conn = NULL,
  name = NULL,
  new_column = "h3string",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_bigint_to_lon(
  x,
  h3bigint = "h3bigint",
  conn = NULL,
  name = NULL,
  new_column = "lon",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_bigint_to_lat(
  x,
  h3bigint = "h3bigint",
  conn = NULL,
  name = NULL,
  new_column = "lat",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_bigint_to_spatial(
  x,
  h3bigint = "h3bigint",
  conn = NULL,
  name = NULL,
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

- h3bigint:

  The name of a column in `x` containing the H3 UBIGINT

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

- `ddbh3_bigint_to_strings()` converts H3 indexes to strings (e.g.
  `"8928308280fffff"`)

- `ddbh3_bigint_to_spatial()` converts H3 indexes to spatial hexagon
  polygons

- `ddbh3_bigint_to_lon()` extracts the longitude of the H3 cell centroid

- `ddbh3_bigint_to_lat()` extracts the latitude of the H3 cell centroid

## Examples

``` r
if (FALSE) { # \dontrun{
## TODO
} # }
```
