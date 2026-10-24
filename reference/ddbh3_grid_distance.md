# Get the grid distance between two H3 cells

Computes the minimum number of step-by-step neighbor hops required to
travel from a starting H3 cell to a destination H3 cell.

## Usage

``` r
ddbh3_grid_distance(
  x,
  h3start = "h3string",
  h3end,
  new_column = "grid_distance",
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

- h3start:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`). The path starts on this cell

- h3end:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`). It's the destination cell of the path

- new_column:

  Character. Name of the new column to be created. Defaults to
  `"grid_distance"`.

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
  setting.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

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

## Examples

``` r
## Load packages
library(duckh3)
library(duckspatial)
ddbh3_default_conn()

## Create a data frame with the start and end of the path
h3_tbl <- data.frame(
  h3start = "883923059bfffff",
  h3end   = "883923d04dfffff"
)

## Get the number of cells distance between them
ddbh3_grid_distance(
  h3_tbl,
  h3start = "h3start",
  h3end = "h3end"
)
#> # A query:  ?? x 3
#> # Database: DuckDB 1.5.6 [unknown@Linux 6.17.0-1022-azure:R 4.6.1/:memory:]
#>   h3start         h3end           grid_distance
#>   <chr>           <chr>                 <int64>
#> 1 883923059bfffff 883923d04dfffff            97
```
