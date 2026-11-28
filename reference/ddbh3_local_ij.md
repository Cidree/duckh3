# Work with H3 local IJ coordinates

Convert H3 cells to local IJ coordinates relative to an origin cell, and
local IJ coordinates back to H3 cells

## Usage

``` r
ddbh3_h3_to_local_ij(
  x,
  origin,
  h3 = "h3string",
  new_column = c("i", "j"),
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_local_ij_to_h3(
  x,
  origin,
  i = "i",
  j = "j",
  new_column = "h3cell",
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

- origin:

  The name of a column in `x` containing the H3 cells used as origin of
  the local IJ coordinate system

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- new_column:

  Name of the new column(s) to create on the input data. For
  `ddbh3_h3_to_local_ij()`, a character vector of length 2 with the
  names of the I and J columns (defaults to `c("i", "j")`). For
  `ddbh3_local_ij_to_h3()`, the name of the cell column (defaults to
  `"h3cell"`). If the input already has a column with any of these
  names, it is replaced by the result

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

- i, j:

  The names of the columns in `x` containing the local I and J
  coordinates

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

Local IJ coordinates are integer coordinates of a cell in a 2D grid
anchored at an origin cell. They are useful to work with cells as a
regular grid (e.g. offsets between cells or image-like operations):

- `ddbh3_h3_to_local_ij()` adds two integer columns with the I and J
  coordinates of the cell in `h3` relative to the cell in `origin`

- `ddbh3_local_ij_to_h3()` returns the cell at the I and J coordinates
  relative to the cell in `origin`. The cell is returned in the same
  format as `origin` (string or `UBIGINT`)

Local IJ coordinates are only defined near the origin: the origin and
the cell must have the same resolution and be close enough to each other
(and not cross pentagon distortion). Otherwise, the result is `NA`. The
origin is not placed at `(0, 0)`, and the coordinates are only
comparable between cells that share the same origin.

Both functions work inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
There, `ddbh3_h3_to_local_ij(origin, h3)` returns a list column with the
`[i, j]` pair; use `ij[[1]]` and `ij[[2]]` to extract each coordinate.

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Cells within 2 steps of an origin cell
cells_tbl <- data.frame(origin = "88283470a1fffff") |>
  ddbh3_grid_disk(k = 2, h3 = "origin", new_column = "h3string")

## CELLS TO LOCAL IJ ------

## Local IJ coordinates relative to the origin
ij_tbl <- ddbh3_h3_to_local_ij(cells_tbl, origin = "origin")
ij_tbl
#> # A query:  ?? x 4
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    origin          h3string            i     j
#>    <chr>           <chr>           <int> <int>
#>  1 88283470a1fffff 88283470a1fffff   454   394
#>  2 88283470a1fffff 88283470adfffff   455   395
#>  3 88283470a1fffff 88283470a5fffff   454   395
#>  4 88283470a1fffff 88283470a7fffff   453   394
#>  5 88283470a1fffff 88283470a3fffff   453   393
#>  6 88283470a1fffff 88283470abfffff   454   393
#>  7 88283470a1fffff 88283470a9fffff   455   394
#>  8 88283470a1fffff 88283470e7fffff   456   395
#>  9 88283470a1fffff 88283471dbfffff   456   396
#> 10 88283470a1fffff 88283471d3fffff   455   396
#> 11 88283470a1fffff 8828347199fffff   454   396
#> 12 88283470a1fffff 882834719bfffff   453   395
#> 13 88283470a1fffff 882834624dfffff   452   394
#> 14 88283470a1fffff 8828346249fffff   452   393
#> 15 88283470a1fffff 88283470b5fffff   452   392
#> 16 88283470a1fffff 88283470bdfffff   453   392
#> 17 88283470a1fffff 8828347087fffff   454   392
#> 18 88283470a1fffff 8828347085fffff   455   393
#> 19 88283470a1fffff 88283470e3fffff   456   394

## Custom column names
ddbh3_h3_to_local_ij(cells_tbl, origin = "origin", new_column = c("col", "row"))
#> # A query:  ?? x 4
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    origin          h3string          col   row
#>    <chr>           <chr>           <int> <int>
#>  1 88283470a1fffff 88283470a1fffff   454   394
#>  2 88283470a1fffff 88283470adfffff   455   395
#>  3 88283470a1fffff 88283470a5fffff   454   395
#>  4 88283470a1fffff 88283470a7fffff   453   394
#>  5 88283470a1fffff 88283470a3fffff   453   393
#>  6 88283470a1fffff 88283470abfffff   454   393
#>  7 88283470a1fffff 88283470a9fffff   455   394
#>  8 88283470a1fffff 88283470e7fffff   456   395
#>  9 88283470a1fffff 88283471dbfffff   456   396
#> 10 88283470a1fffff 88283471d3fffff   455   396
#> 11 88283470a1fffff 8828347199fffff   454   396
#> 12 88283470a1fffff 882834719bfffff   453   395
#> 13 88283470a1fffff 882834624dfffff   452   394
#> 14 88283470a1fffff 8828346249fffff   452   393
#> 15 88283470a1fffff 88283470b5fffff   452   392
#> 16 88283470a1fffff 88283470bdfffff   453   392
#> 17 88283470a1fffff 8828347087fffff   454   392
#> 18 88283470a1fffff 8828347085fffff   455   393
#> 19 88283470a1fffff 88283470e3fffff   456   394

## LOCAL IJ TO CELLS ------

## Back to the original cells
ddbh3_local_ij_to_h3(ij_tbl, origin = "origin")
#> # A query:  ?? x 5
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    origin          h3string            i     j h3cell         
#>    <chr>           <chr>           <int> <int> <chr>          
#>  1 88283470a1fffff 88283470a1fffff   454   394 88283470a1fffff
#>  2 88283470a1fffff 88283470adfffff   455   395 88283470adfffff
#>  3 88283470a1fffff 88283470a5fffff   454   395 88283470a5fffff
#>  4 88283470a1fffff 88283470a7fffff   453   394 88283470a7fffff
#>  5 88283470a1fffff 88283470a3fffff   453   393 88283470a3fffff
#>  6 88283470a1fffff 88283470abfffff   454   393 88283470abfffff
#>  7 88283470a1fffff 88283470a9fffff   455   394 88283470a9fffff
#>  8 88283470a1fffff 88283470e7fffff   456   395 88283470e7fffff
#>  9 88283470a1fffff 88283471dbfffff   456   396 88283471dbfffff
#> 10 88283470a1fffff 88283471d3fffff   455   396 88283471d3fffff
#> 11 88283470a1fffff 8828347199fffff   454   396 8828347199fffff
#> 12 88283470a1fffff 882834719bfffff   453   395 882834719bfffff
#> 13 88283470a1fffff 882834624dfffff   452   394 882834624dfffff
#> 14 88283470a1fffff 8828346249fffff   452   393 8828346249fffff
#> 15 88283470a1fffff 88283470b5fffff   452   392 88283470b5fffff
#> 16 88283470a1fffff 88283470bdfffff   453   392 88283470bdfffff
#> 17 88283470a1fffff 8828347087fffff   454   392 8828347087fffff
#> 18 88283470a1fffff 8828347085fffff   455   393 8828347085fffff
#> 19 88283470a1fffff 88283470e3fffff   456   394 88283470e3fffff

## Shift the cells one step along the I axis
ij_tbl |>
  mutate(i = i + 1L) |>
  ddbh3_local_ij_to_h3(origin = "origin", new_column = "h3shifted")
#> # A query:  ?? x 5
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    origin          h3string            i     j h3shifted      
#>    <chr>           <chr>           <int> <int> <chr>          
#>  1 88283470a1fffff 88283470a1fffff   455   394 88283470a9fffff
#>  2 88283470a1fffff 88283470adfffff   456   395 88283470e7fffff
#>  3 88283470a1fffff 88283470a5fffff   455   395 88283470adfffff
#>  4 88283470a1fffff 88283470a7fffff   454   394 88283470a1fffff
#>  5 88283470a1fffff 88283470a3fffff   454   393 88283470abfffff
#>  6 88283470a1fffff 88283470abfffff   455   393 8828347085fffff
#>  7 88283470a1fffff 88283470a9fffff   456   394 88283470e3fffff
#>  8 88283470a1fffff 88283470e7fffff   457   395 88283470e1fffff
#>  9 88283470a1fffff 88283471dbfffff   457   396 88283470e5fffff
#> 10 88283470a1fffff 88283471d3fffff   456   396 88283471dbfffff
#> 11 88283470a1fffff 8828347199fffff   455   396 88283471d3fffff
#> 12 88283470a1fffff 882834719bfffff   454   395 88283470a5fffff
#> 13 88283470a1fffff 882834624dfffff   453   394 88283470a7fffff
#> 14 88283470a1fffff 8828346249fffff   453   393 88283470a3fffff
#> 15 88283470a1fffff 88283470b5fffff   453   392 88283470bdfffff
#> 16 88283470a1fffff 88283470bdfffff   454   392 8828347087fffff
#> 17 88283470a1fffff 8828347087fffff   455   392 8828347081fffff
#> 18 88283470a1fffff 8828347085fffff   456   393 882834708dfffff
#> 19 88283470a1fffff 88283470e3fffff   457   394 88283470ebfffff

## Inside mutate (`ij[[1]]` extracts the I coordinate)
ij_tbl |>
  mutate(
    ij = ddbh3_h3_to_local_ij(origin, h3string),
    i_mutate = ij[[1]],
    h3cell = ddbh3_local_ij_to_h3(origin, i, j)
  )
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>    origin          h3string            i     j ij        i_mutate h3cell        
#>    <chr>           <chr>           <int> <int> <list>       <int> <chr>         
#>  1 88283470a1fffff 88283470a1fffff   454   394 <int [2]>      454 88283470a1fff…
#>  2 88283470a1fffff 88283470adfffff   455   395 <int [2]>      455 88283470adfff…
#>  3 88283470a1fffff 88283470a5fffff   454   395 <int [2]>      454 88283470a5fff…
#>  4 88283470a1fffff 88283470a7fffff   453   394 <int [2]>      453 88283470a7fff…
#>  5 88283470a1fffff 88283470a3fffff   453   393 <int [2]>      453 88283470a3fff…
#>  6 88283470a1fffff 88283470abfffff   454   393 <int [2]>      454 88283470abfff…
#>  7 88283470a1fffff 88283470a9fffff   455   394 <int [2]>      455 88283470a9fff…
#>  8 88283470a1fffff 88283470e7fffff   456   395 <int [2]>      456 88283470e7fff…
#>  9 88283470a1fffff 88283471dbfffff   456   396 <int [2]>      456 88283471dbfff…
#> 10 88283470a1fffff 88283471d3fffff   455   396 <int [2]>      455 88283471d3fff…
#> 11 88283470a1fffff 8828347199fffff   454   396 <int [2]>      454 8828347199fff…
#> 12 88283470a1fffff 882834719bfffff   453   395 <int [2]>      453 882834719bfff…
#> 13 88283470a1fffff 882834624dfffff   452   394 <int [2]>      452 882834624dfff…
#> 14 88283470a1fffff 8828346249fffff   452   393 <int [2]>      452 8828346249fff…
#> 15 88283470a1fffff 88283470b5fffff   452   392 <int [2]>      452 88283470b5fff…
#> 16 88283470a1fffff 88283470bdfffff   453   392 <int [2]>      453 88283470bdfff…
#> 17 88283470a1fffff 8828347087fffff   454   392 <int [2]>      454 8828347087fff…
#> 18 88283470a1fffff 8828347085fffff   455   393 <int [2]>      455 8828347085fff…
#> 19 88283470a1fffff 88283470e3fffff   456   394 <int [2]>      456 88283470e3fff…
```
