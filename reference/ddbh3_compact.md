# Compact and uncompact sets of H3 cells

Compact a set of H3 cells into the smallest set of (possibly coarser)
cells covering the same area, or uncompact a set of cells to a single
resolution

## Usage

``` r
ddbh3_compact(
  x,
  h3 = "h3string",
  by = NULL,
  new_column = "h3compact",
  nested = FALSE,
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_uncompact(
  x,
  h3 = "h3string",
  resolution = 8,
  new_column = "h3uncompact",
  nested = FALSE,
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

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- by:

  Character vector with the names of the columns used to group the cells
  before compacting them (e.g. one compacted set per region). If `NULL`
  (default), all the cells of `x` are compacted together.

- new_column:

  Name of the new column to create on the input data. Defaults to
  `"h3compact"` for `ddbh3_compact()` and `"h3uncompact"` for
  `ddbh3_uncompact()`.

- nested:

  Logical. If `TRUE`, the cells are returned as a nested list column
  (one row per group in `ddbh3_compact()`, one row per input row in
  `ddbh3_uncompact()`). If `FALSE` (default), the result is unnested so
  each cell occupies its own row.

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

- resolution:

  A number specifying the resolution of the uncompacted cells (between 0
  and 15). It must be equal to or finer than the resolution of every
  input cell.

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

## Value

For `ddbh3_compact()`, a `tbl_lazy` (or `TRUE` invisibly if `name` is
provided). For `ddbh3_uncompact()`, the same outputs as the rest of the
package:

- `tbl_lazy`:

  If `x` is not spatial. `mode` is ignored in this case.

- `duckspatial_df`:

  If `x` is spatial (e.g. an `sf` or `duckspatial_df` object) and
  `mode = "duckspatial"` (default).

- `sf`:

  If `x` is spatial and `mode = "sf"`.

- `TRUE` (invisibly):

  If `name` is provided, a table is created in the connection and `TRUE`
  is returned invisibly.

In vectorized mode (`x` is a vector of cells and `conn = NULL`), both
functions return a vector with the compacted or uncompacted set of
cells.

## Details

- `ddbh3_compact()` is an aggregation: it replaces every complete set of
  children by their parent, recursively. The output only keeps the `by`
  columns and the compacted cells, and it is never spatial (use
  [`ddbh3_h3_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  to get the hexagons). Duplicated cells are removed before compacting.
  If a group contains invalid cells, its result is `NULL` (with
  `nested = TRUE`) or the group is dropped (with `nested = FALSE`). The
  `h3` column can also be a list column of cells.

- `ddbh3_uncompact()` expands each cell (or each list of cells, if `h3`
  is a list column) to all its descendants at `resolution`. Cells
  already at `resolution` are kept. It keeps the rest of the columns. If
  a cell is finer than `resolution`, the result for that row is `NULL`
  (with `nested = TRUE`) or the row is dropped (with `nested = FALSE`).

Inside `dplyr`, `ddbh3_compact(h3)` works as an aggregate function in
[`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html),
and `ddbh3_uncompact(h3, resolution)` works in
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) on a
list column of cells.

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpuK9Fi7/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.

## All the children of two cells, plus one extra cell
cells_tbl <- data.frame(
  region   = c("A", "B", "B"),
  h3string = c("87283472bffffff", "872834729ffffff", "88283470a1fffff")
) |>
  ddbh3_get_children(resolution = 8, h3 = "h3string", new_column = "h3children")

## COMPACT ------------------

## Compact all the cells together
ddbh3_compact(cells_tbl, h3 = "h3children")
#> # A query:  ?? x 1
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   h3compact      
#>   <chr>          
#> 1 88283470a1fffff
#> 2 872834729ffffff
#> 3 87283472bffffff

## Compact the cells of each region
compact_tbl <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region")
compact_tbl
#> # A query:  ?? x 2
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   region h3compact      
#>   <chr>  <chr>          
#> 1 A      87283472bffffff
#> 2 B      88283470a1fffff
#> 3 B      872834729ffffff

## One row per region with a list of cells
ddbh3_compact(cells_tbl, h3 = "h3children", by = "region", nested = TRUE)
#> # A query:  ?? x 2
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   region h3compact
#>   <chr>  <list>   
#> 1 A      <chr [1]>
#> 2 B      <chr [2]>

## Inside summarise
cells_tbl |>
  summarise(h3compact = ddbh3_compact(h3children), .by = region)
#> # A query:  ?? x 2
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   region h3compact
#>   <chr>  <list>   
#> 1 A      <chr [1]>
#> 2 B      <chr [2]>

## UNCOMPACT ----------------

## Back to resolution 8
ddbh3_uncompact(compact_tbl, h3 = "h3compact", resolution = 8)
#> # A query:  ?? x 3
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    region h3compact       h3uncompact    
#>    <chr>  <chr>           <chr>          
#>  1 A      87283472bffffff 88283472b1fffff
#>  2 A      87283472bffffff 88283472b3fffff
#>  3 A      87283472bffffff 88283472b5fffff
#>  4 A      87283472bffffff 88283472b7fffff
#>  5 A      87283472bffffff 88283472b9fffff
#>  6 A      87283472bffffff 88283472bbfffff
#>  7 A      87283472bffffff 88283472bdfffff
#>  8 B      88283470a1fffff 88283470a1fffff
#>  9 B      872834729ffffff 8828347291fffff
#> 10 B      872834729ffffff 8828347293fffff
#> 11 B      872834729ffffff 8828347295fffff
#> 12 B      872834729ffffff 8828347297fffff
#> 13 B      872834729ffffff 8828347299fffff
#> 14 B      872834729ffffff 882834729bfffff
#> 15 B      872834729ffffff 882834729dfffff

## Vectorized mode
ddbh3_uncompact("87283472bffffff", resolution = 8) |>
  ddbh3_compact()
#> [1] "87283472bffffff"
```
