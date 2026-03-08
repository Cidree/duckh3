# Get the position of an H3 cell within its parent

Get the position of H3 cell indexes stored as strings or unsigned 64-bit
integers (`UBIGINT`) within their parent cell at a specified resolution.
The position is a zero-based index among all children of the parent
cell.

## Usage

``` r
ddbh3_get_child_pos(
  x,
  resolution,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "h3child_pos",
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

## Examples

``` r
if (FALSE) { # \dontrun{
## TODO
} # }
```
