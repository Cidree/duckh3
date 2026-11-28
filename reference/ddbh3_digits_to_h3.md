# Build H3 cells from a base cell and digits

Build H3 cell indexes from a base cell number and a set of indexing
digits

## Usage

``` r
ddbh3_digits_to_h3(
  x,
  base_cell = "base_cell",
  digits = "digits",
  new_column = "h3string",
  h3_format = "string",
  conn = NULL,
  name = NULL,
  mode = NULL,
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

- base_cell:

  The name of a column in `x` containing the base cell numbers (between
  0 and 121)

- digits:

  The name of a list column in `x` containing the digits of the cells
  (integers between 0 and 6, one per resolution)

- new_column:

  Name of the new column to create on the input data. Defaults to
  `"h3string"`. If the input already has a column with this name, it is
  replaced by the result

- h3_format:

  Character. The format of the H3 cell index: `"string"` (default) or
  `"bigint"`

- conn:

  A connection object to a DuckDB database. If `NULL`, the function runs
  on a temporary DuckDB database.

- name:

  A character string of length one specifying the name of the table, or
  a character string of length two specifying the schema and table
  names. If `NULL` (the default), the function returns the result as an
  `sf` object

- mode:

  Character. Controls the return type. Options:

  - `"duckspatial"` (default): Lazy spatial data frame backed by
    dbplyr/DuckDB

  - `"sf"`: Eagerly collected sf object (uses memory)

  Can be set globally via
  [`ddbs_options`](https://cidree.github.io/duckspatial/reference/ddbs_options.html)`(mode = "...")`
  or per-function via this argument. Per-function overrides global
  setting. It only applies when the output has a geometry column, and is
  ignored otherwise.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

## Value

One of the following, depending on the inputs:

- `tbl_lazy`:

  If the output has no geometry, i.e. `x` is not spatial and the
  function adds a column. `mode` is ignored in this case.

- `duckspatial_df`:

  If the output has geometry (`x` is spatial, e.g. an `sf` or
  `duckspatial_df` object, or the function builds geometries, as
  `*_to_spatial()` and
  [`ddbh3_h3_to_points()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  do) and `mode = "duckspatial"` (default).

- `sf`:

  If the output has geometry and `mode = "sf"`.

- `TRUE` (invisibly):

  If `name` is provided, a table is created in the connection and `TRUE`
  is returned invisibly.

- vector:

  If `x` is a character vector and `conn = NULL`, the function operates
  in vectorized mode, returning a vector of the same length as `x`.

## Details

An H3 cell index is made of a base cell (one of the 122 cells of
resolution 0, see
[`ddbh3_get_base_cell_number()`](https://cidree.github.io/duckh3/reference/ddbh3_get_base_cell_number.md))
and one digit (between 0 and 6) per resolution, from resolution 1 to the
resolution of the cell. Each digit is the position of the cell among the
7 children of its parent (pentagons have no digit 1 child).

The resolution of the built cell is the number of digits, so an empty
list returns the base cell itself (resolution 0). The function returns
`NA` when the base cell or any digit is not valid.

It also works inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
where it always returns H3 strings.

## See also

[`ddbh3_get_base_cell_number()`](https://cidree.github.io/duckh3/reference/ddbh3_get_base_cell_number.md),
[`ddbh3_get_child_pos()`](https://cidree.github.io/duckh3/reference/ddbh3_get_child_pos.md)

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Base cells and digits (the first row is the cell 88283470a1fffff)
digits_df <- data.frame(base_cell = c(20, 20, 0))
digits_df$digits <- list(c(0, 6, 4, 3, 4, 1, 2, 0), c(0, 6, 4), numeric(0))

## Build the cells
ddbh3_digits_to_h3(digits_df)
#> # A query:  ?? x 3
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   base_cell digits    h3string       
#>       <dbl> <list>    <chr>          
#> 1        20 <dbl [8]> 88283470a1fffff
#> 2        20 <dbl [3]> 832834fffffffff
#> 3         0 <dbl [0]> 8001fffffffffff

## As UBIGINT
ddbh3_digits_to_h3(digits_df, h3_format = "bigint")
#> # A query:  ?? x 3
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   base_cell digits    h3string
#>       <dbl> <list>     <int64>
#> 1        20 <dbl [8]>     6e17
#> 2        20 <dbl [3]>     5e17
#> 3         0 <dbl [0]>     5e17

## Inside mutate
ddbh3_digits_to_h3(digits_df, new_column = "h3cell") |>
  mutate(
    h3string = ddbh3_digits_to_h3(base_cell, digits),
    resolution = ddbh3_get_resolution(h3string)
  )
#> # A query:  ?? x 5
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   base_cell digits    h3cell          h3string        resolution
#>       <dbl> <list>    <chr>           <chr>                <int>
#> 1        20 <dbl [8]> 88283470a1fffff 88283470a1fffff          8
#> 2        20 <dbl [3]> 832834fffffffff 832834fffffffff          3
#> 3         0 <dbl [0]> 8001fffffffffff 8001fffffffffff          0
```
