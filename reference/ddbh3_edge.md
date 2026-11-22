# Work with H3 directed edges

Create H3 directed edges from H3 cells, and convert H3 directed edges to
cells, lengths and spatial lines. A directed edge goes from an origin
cell to one of its neighbors (the destination cell)

## Usage

``` r
ddbh3_h3_to_edge(
  x,
  h3start = "h3string",
  h3end,
  new_column = "h3edge",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_edges(
  x,
  h3 = "h3string",
  new_column = "h3edge",
  nested = FALSE,
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_edge_to_origin(
  x,
  h3edge = "h3edge",
  new_column = "h3origin",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_edge_to_destination(
  x,
  h3edge = "h3edge",
  new_column = "h3destination",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_edge_to_h3(
  x,
  h3edge = "h3edge",
  new_column = "h3cells",
  nested = FALSE,
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_reverse_edge(
  x,
  h3edge = "h3edge",
  new_column = "h3edge_reversed",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_get_edge_length(
  x,
  h3edge = "h3edge",
  unit = "m",
  new_column = "edge_length",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_edge_to_spatial(
  x,
  h3edge = "h3edge",
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

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result. If the input already
  has a column with this name, it is replaced by the result

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

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- nested:

  Logical. If `TRUE`, children are returned as a nested list column (one
  row per parent cell). If `FALSE` (default), the result is unnested so
  each child cell occupies its own row.

- h3edge:

  Name of the column containing H3 directed edge indexes, as strings or
  unsigned 64-bit integers (`UBIGINT`). Defaults to `"h3edge"`

- unit:

  Character. Unit of the edge length. One of `"m"` (default), `"km"` or
  `"rads"`. Only used in `ddbh3_get_edge_length()`.

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

## Details

The functions cover the full directed edge workflow:

- `ddbh3_h3_to_edge()` returns the directed edge going from the cell in
  `h3start` to the cell in `h3end`. It returns `NA` when the cells are
  not neighbors

- `ddbh3_h3_to_edges()` returns all directed edges going out of an H3
  cell (6 for hexagons, 5 for pentagons) — either nested (one row per
  cell) or unnested (one row per edge) depending on `nested`

- `ddbh3_edge_to_origin()` returns the origin cell of a directed edge

- `ddbh3_edge_to_destination()` returns the destination cell of a
  directed edge

- `ddbh3_edge_to_h3()` returns both the origin and the destination cells
  of a directed edge — either nested (one row per edge) or unnested (one
  row per cell) depending on `nested`

- `ddbh3_reverse_edge()` returns the directed edge going in the opposite
  direction (from destination to origin)

- `ddbh3_get_edge_length()` returns the length of a directed edge in
  `unit`

- `ddbh3_edge_to_spatial()` converts directed edges to `LINESTRING`
  geometries (`EPSG:4326`) shared by the origin and destination cells

Directed edges are returned in the same format as the input cells:
strings for H3 strings and `UBIGINT` for H3 unsigned 64-bit integers.

## Examples

``` r
## Load needed packages
library(duckh3)
library(dplyr)

## Setup the default connection with h3 and spatial extensions
## This is a mandatory step to use duckh3 functions
ddbh3_default_conn(threads = 1)

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)

## Add h3 strings
points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)

## CELLS TO EDGES ---------

## All edges going out of each cell (one row per edge)
edges_tbl <- ddbh3_h3_to_edges(points_tbl)

## All edges going out of each cell (one row per cell)
ddbh3_h3_to_edges(points_tbl, nested = TRUE)
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        h3edge   
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <list>   
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff <chr [6]>
#>  2     2     2  29.2   61.9  C        884221ac65fffff <chr [6]>
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff <chr [6]>
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff <chr [6]>
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff <chr [6]>
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff <chr [6]>
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff <chr [6]>
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff <chr [6]>
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff <chr [6]>
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff <chr [6]>
#> # ℹ more rows

## Edge between two neighboring cells
pair_tbl <- data.frame(
  h3start = "8a1fb46622dffff",
  h3end   = "8a1fb46622d7fff"
)
ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = "h3end")
#> # A query:  ?? x 3
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>   h3start         h3end           h3edge          
#>   <chr>           <chr>           <chr>           
#> 1 8a1fb46622dffff 8a1fb46622d7fff 16a1fb46622dffff

## EDGES TO CELLS ---------

## Origin and destination cells
edges_tbl |>
  ddbh3_edge_to_origin() |>
  ddbh3_edge_to_destination()
#> # A query:  ?? x 9
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string       h3edge h3origin h3destination
#>    <int> <int> <dbl> <dbl> <chr>    <chr>          <chr>  <chr>    <chr>        
#>  1     1     1 -43.1  16.2 B        88d02dcc19fff… 118d0… 88d02dc… 88d02dcc1bff…
#>  2     1     1 -43.1  16.2 B        88d02dcc19fff… 128d0… 88d02dc… 88d02dcc1dff…
#>  3     1     1 -43.1  16.2 B        88d02dcc19fff… 138d0… 88d02dc… 88d02dcc11ff…
#>  4     1     1 -43.1  16.2 B        88d02dcc19fff… 148d0… 88d02dc… 88d02dcc53ff…
#>  5     1     1 -43.1  16.2 B        88d02dcc19fff… 158d0… 88d02dc… 88d02dcea5ff…
#>  6     1     1 -43.1  16.2 B        88d02dcc19fff… 168d0… 88d02dc… 88d02dcc57ff…
#>  7     2     2  29.2  61.9 C        884221ac65fff… 11842… 884221a… 884221ac67ff…
#>  8     2     2  29.2  61.9 C        884221ac65fff… 12842… 884221a… 884221ad59ff…
#>  9     2     2  29.2  61.9 C        884221ac65fff… 13842… 884221a… 884221ad5bff…
#> 10     2     2  29.2  61.9 C        884221ac65fff… 14842… 884221a… 884221ac6dff…
#> # ℹ more rows

## Both cells in a list column
ddbh3_edge_to_h3(edges_tbl, nested = TRUE)
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           h3cells  
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <list>   
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff <chr [2]>
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff <chr [2]>
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff <chr [2]>
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff <chr [2]>
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff <chr [2]>
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff <chr [2]>
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff <chr [2]>
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff <chr [2]>
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff <chr [2]>
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff <chr [2]>
#> # ℹ more rows

## Reverse the direction of the edges
ddbh3_reverse_edge(edges_tbl)
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge       h3edge_reversed
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>        <chr>          
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19… 168d02dcc1bfff…
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19… 158d02dcc1dfff…
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19… 148d02dcc11fff…
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19… 138d02dcc53fff…
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19… 128d02dcea5fff…
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19… 118d02dcc57fff…
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65… 1684221ac67fff…
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65… 1584221ad59fff…
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65… 1484221ad5bfff…
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65… 1384221ac6dfff…
#> # ℹ more rows

## EDGE PROPERTIES --------

## Length of the edges in kilometers
ddbh3_get_edge_length(edges_tbl, unit = "km")
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           edge_length
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>                  <dbl>
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff       0.540
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff       0.517
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff       0.505
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff       0.505
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff       0.517
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff       0.540
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff       0.536
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff       0.555
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff       0.532
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff       0.532
#> # ℹ more rows

## Inside mutate
edges_tbl |>
  mutate(
    origin = ddbh3_edge_to_origin(h3edge),
    length = ddbh3_get_edge_length(h3edge, 'm')
  )
#> # A query:  ?? x 9
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge         origin length
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>          <chr>   <dbl>
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19ff… 88d02…   540.
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19ff… 88d02…   517.
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19ff… 88d02…   505.
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19ff… 88d02…   505.
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19ff… 88d02…   517.
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19ff… 88d02…   540.
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65ff… 88422…   536.
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65ff… 88422…   555.
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65ff… 88422…   532.
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65ff… 88422…   532.
#> # ℹ more rows

## EDGES TO SPATIAL -------

## Convert edges to lines
ddbh3_edge_to_spatial(edges_tbl)
#> # A duckspatial lazy spatial table
#> # ● CRS: EPSG:4326 
#> # ● Geometry column: geometry 
#> # ● Geometry type: LINESTRING 
#> # ● Bounding box: xmin: -97.944 ymin: -59.99 xmax: 94.807 ymax: 59.812 
#> # Data backed by DuckDB (dbplyr lazy evaluation)
#> # Use ddbs_collect() or st_as_sf() to materialize to sf
#> #
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.0 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           geometry   
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <wk_wkb>   
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff <LINESTRIN…
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff <LINESTRIN…
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff <LINESTRIN…
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff <LINESTRIN…
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff <LINESTRIN…
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff <LINESTRIN…
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff <LINESTRIN…
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff <LINESTRIN…
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff <LINESTRIN…
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff <LINESTRIN…
#> # ℹ more rows
```
