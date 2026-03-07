# Check properties of H3 cell indexes

Check properties of H3 cell indexes stored as strings or unsigned 64-bit
integers

## Usage

``` r
ddbh3_is_pentagon(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "ispentagon",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_valid(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "isvalid",
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_res_class_iii(
  x,
  h3 = "h3string",
  conn = NULL,
  name = NULL,
  new_column = "isclassiii",
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

The three functions check different properties of H3 cell indexes, all
returning a logical column:

- `ddbh3_is_pentagon()` returns `TRUE` if the H3 cell is one of the 12
  pentagonal cells that exist at each H3 resolution

- `ddbh3_is_valid()` returns `TRUE` if the H3 cell index is a valid H3
  cell

- `ddbh3_is_res_class_iii()` returns `TRUE` if the H3 cell belongs to a
  Class III resolution (odd resolutions: 1, 3, 5, 7, 9, 11, 13, 15)

## Examples

``` r
if (FALSE) { # \dontrun{
## TODO
} # }
```
