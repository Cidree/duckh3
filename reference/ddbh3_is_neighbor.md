# Check if two H3 cells are neighbors

Checks whether two H3 cells share an edge (i.e. they are directly
adjacent). Cells at different resolutions are never neighbors.

## Usage

``` r
ddbh3_is_neighbor(
  x,
  h3start = "h3string",
  h3end,
  new_column = "isneighbor",
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
  `"isneighbor"`.

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

## Examples

``` r
## Load packages
library(duckh3)
library(dplyr)
ddbh3_default_conn(threads = 1)

## Create a data frame with pairs of cells
h3_tbl <- data.frame(
  h3start = c("8a1fb46622dffff", "883923059bfffff"),
  h3end   = c("8a1fb46622d7fff", "883923d04dfffff")
)

## Check if they are neighbors
ddbh3_is_neighbor(h3_tbl, h3start = "h3start", h3end = "h3end")
#> # A query:  ?? x 3
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   h3start         h3end           isneighbor
#>   <chr>           <chr>           <lgl>     
#> 1 8a1fb46622dffff 8a1fb46622d7fff TRUE      
#> 2 883923059bfffff 883923d04dfffff FALSE     

## Check in mutate
h3_tbl |>
  ddbh3_is_neighbor(h3start = "h3start", h3end = "h3end") |>
  mutate(edge = ddbh3_h3_to_edge(h3start, h3end))
#> # A query:  ?? x 4
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   h3start         h3end           isneighbor edge            
#>   <chr>           <chr>           <lgl>      <chr>           
#> 1 8a1fb46622dffff 8a1fb46622d7fff TRUE       16a1fb46622dffff
#> 2 883923059bfffff 883923d04dfffff FALSE      NA              
```
