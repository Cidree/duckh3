# Convert H3 cell indexes to vertex representations

Convert H3 cell indexes stored as strings or unsigned 64-bit integers
(`UBIGINT`) to their vertex representations

## Usage

``` r
ddbh3_h3_to_vertex(
  x,
  n = 0,
  h3 = "h3string",
  new_column = "h3vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lon(
  x,
  h3vertex = "h3vertex",
  new_column = "lon_vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_lat(
  x,
  h3vertex = "h3vertex",
  new_column = "lat_vertex",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_h3_to_vertexes(
  x,
  h3 = "h3string",
  new_column = "h3vertex",
  conn = NULL,
  name = NULL,
  nested = FALSE,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_vertex_to_spatial(
  x,
  h3vertex = "h3vertex",
  conn = NULL,
  name = NULL,
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

- n:

  Integer. Vertex number to retrieve. Must be in the range 0–5 for
  hexagons and 0–4 for pentagons. Only used in `ddbh3_h3_to_vertex()`.

- h3:

  The name of a column in `x` containing the H3 strings or H3 unsigned
  64-bit integers (`UBIGINT`)

- new_column:

  Name of the new column to create on the input data. If NULL, the
  function will return a vector with the result

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

- h3vertex:

  Name of the column containing H3 vertex strings. Defaults to
  `"h3vertex"`

- nested:

  Logical. If `TRUE`, children are returned as a nested list column (one
  row per parent cell). If `FALSE` (default), the result is unnested so
  each child cell occupies its own row.

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

The functions cover the full vertex workflow:

- `ddbh3_h3_to_vertex()` returns a single vertex of an H3 cell,
  identified by its vertex number `n` (0–5 for hexagons, 0–4 for
  pentagons), as an H3 vertex string

- `ddbh3_h3_to_vertexes()` returns all vertices of an H3 cell as H3
  vertex strings — either nested (one row per cell) or unnested (one row
  per vertex) depending on `nested`

- `ddbh3_vertex_to_lat()` returns the latitude of an H3 vertex string

- `ddbh3_vertex_to_lon()` returns the longitude of an H3 vertex string

- `ddbh3_vertex_to_spatial()` converts H3 vertex strings to spatial
  point geometries. If the input column is nested, vertices are
  automatically unnested and aggregated into a `MULTIPOINT` geometry per
  cell

## Examples

``` r
## Load needed packages
library(duckh3)
library(duckspatial)
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

## TO VERTEX ---------------

## Add second vertex
vertex_2_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 2)

## Add add vertexes (unnested)
vertexes_tbl <- ddbh3_h3_to_vertexes(points_tbl)

## Add add vertexes (nested)
vertexes_nested_tbl <- ddbh3_h3_to_vertexes(points_tbl, nested = TRUE)

## Add some vertexes with with mutate
points_tbl |> 
  mutate(
    v1 = ddbh3_h3_to_vertex(h3string, 1),
    v3 = ddbh3_h3_to_vertex(h3string, 3)
  )
#> # Source:   SQL [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0/:memory:]
#>        X    id    lat    lon category h3string        v1               v3       
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>            <chr>    
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 218d02dcc19fffff 258d02dc…
#>  2     2     2  29.2   61.9  C        884221ac65fffff 2184221ac65fffff 2384221a…
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 238a20e8a97fffff 258a20e8…
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 238181c6c83fffff 238181c6…
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 258e6cece43fffff 218e6cec…
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 258e69d2323fffff 218e69d2…
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 218c1880751fffff 238c1880…
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 238c52b3613fffff 238c52b3…
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 2187b6b5701fffff 2387b6b5…
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 2186d424ae1fffff 2386d424…
#> # ℹ more rows

## VERTEX TO LON/LAT ------

## Add coords
coords_vertex_tbl <- vertex_2_tbl |> 
  ddbh3_vertex_to_lon(new_column = "lon_v2") |> 
  ddbh3_vertex_to_lat(new_column = "lat_v2")

## Add coords in mutate
vertex_2_tbl |> 
  mutate(
    lon_v2 = ddbh3_vertex_to_lon(h3vertex),
    lat_v2 = ddbh3_vertex_to_lat(h3vertex)
  )
#> # Source:   SQL [?? x 9]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0/:memory:]
#>        X    id    lat    lon category h3string        h3vertex     lon_v2 lat_v2
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>         <dbl>  <dbl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 208d02dcc11…  16.2  -43.1 
#>  2     2     2  29.2   61.9  C        884221ac65fffff 2284221ac65…  61.9   29.2 
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 208a20e8f61…  51.3  -20.7 
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 228181c6c95… -14.0   50.9 
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 248e6cece43…   8.70 -57.6 
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 248e69d2323…  21.5  -56.2 
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 228c1880751… -17.0  -33.7 
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 228c52b36c5… -31.9  -32.7 
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 2287b6b5701…  39.0   -7.38
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 2286d424ae1… -89.9   10.0 
#> # ℹ more rows

## VERTEX TO SPATIAL ------

## Convert unnested vertexes (returns POINTS)
ddbh3_h3_to_vertexes(points_tbl) |> 
  ddbh3_vertex_to_spatial()
#> # A duckspatial lazy spatial table
#> # ● CRS: EPSG:4326 
#> # ● Geometry column: geometry 
#> # ● Geometry type: POINT 
#> # ● Bounding box: xmin: -97.944 ymin: -59.99 xmax: 94.807 ymax: 59.812 
#> # Data backed by DuckDB (dbplyr lazy evaluation)
#> # Use ddbs_collect() or st_as_sf() to materialize to sf
#> #
#> # Source:   table<temp_view_c6d3fd75_1c80_4183_9493_f8817110875a> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0/:memory:]
#>        X    id   lat   lon category h3string        h3vertex         geometry   
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <wk_wkb>   
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 208d02dcc19fffff <POINT (16…
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 218d02dcc19fffff <POINT (16…
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 208d02dcc11fffff <POINT (16…
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 258d02dcc11fffff <POINT (16…
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 248d02dcc19fffff <POINT (16…
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 258d02dcc19fffff <POINT (16…
#>  7     2     2  29.2  61.9 C        884221ac65fffff 2084221ac65fffff <POINT (61…
#>  8     2     2  29.2  61.9 C        884221ac65fffff 2184221ac65fffff <POINT (61…
#>  9     2     2  29.2  61.9 C        884221ac65fffff 2284221ac65fffff <POINT (61…
#> 10     2     2  29.2  61.9 C        884221ac65fffff 2384221ac65fffff <POINT (61…
#> # ℹ more rows


## Convert nested vertexes (returns MULTIPOINTS)
ddbh3_h3_to_vertexes(points_tbl, nested = TRUE) |> 
  ddbh3_vertex_to_spatial()
#> # A duckspatial lazy spatial table
#> # ● CRS: EPSG:4326 
#> # ● Geometry column: geometry 
#> # ● Geometry type: MULTIPOINT 
#> # ● Bounding box: xmin: -97.944 ymin: -59.99 xmax: 94.807 ymax: 59.812 
#> # Data backed by DuckDB (dbplyr lazy evaluation)
#> # Use ddbs_collect() or st_as_sf() to materialize to sf
#> #
#> # Source:   table<temp_view_0a9503e6_3a97_4875_b582_baea259bf536> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0/:memory:]
#>        X    id    lat    lon category h3string        h3vertex  geometry        
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <list>    <wk_wkb>        
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff <chr [6]> <MULTIPOINT ((1…
#>  2     2     2  29.2   61.9  C        884221ac65fffff <chr [6]> <MULTIPOINT ((6…
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff <chr [6]> <MULTIPOINT ((5…
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff <chr [6]> <MULTIPOINT ((-…
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff <chr [6]> <MULTIPOINT ((8…
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff <chr [6]> <MULTIPOINT ((2…
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff <chr [6]> <MULTIPOINT ((-…
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff <chr [6]> <MULTIPOINT ((-…
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff <chr [6]> <MULTIPOINT ((3…
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff <chr [6]> <MULTIPOINT ((-…
#> # ℹ more rows
```
