# Check properties of H3 cell indexes

Check properties of H3 cell indexes stored as strings or unsigned 64-bit
integers

## Usage

``` r
ddbh3_is_pentagon(
  x,
  h3 = "h3string",
  new_column = "ispentagon",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_h3(
  x,
  h3 = "h3string",
  new_column = "ish3",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_res_class_iii(
  x,
  h3 = "h3string",
  new_column = "isclassiii",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_vertex(
  x,
  h3vertex = "h3vertex",
  new_column = "isvertex",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_edge(
  x,
  h3edge = "h3edge",
  new_column = "isedge",
  conn = NULL,
  name = NULL,
  mode = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_index(
  x,
  h3 = "h3string",
  new_column = "isindex",
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
  setting. It only applies when the output has a geometry column, and is
  ignored otherwise.

- overwrite:

  Boolean. whether to overwrite the existing table if it exists.
  Defaults to `FALSE`. This argument is ignored when `name` is `NULL`.

- quiet:

  A logical value. If `TRUE`, suppresses any informational messages.
  Defaults to `FALSE`.

- h3vertex:

  Name of the column containing H3 vertex strings. Defaults to
  `"h3vertex"`

- h3edge:

  Name of the column containing H3 directed edge indexes, as strings or
  unsigned 64-bit integers (`UBIGINT`). Defaults to `"h3edge"`

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

The functions check different properties of H3 cell indexes, all
returning a logical column:

- `ddbh3_is_pentagon()`: returns `TRUE` if the H3 cell is one of the 12
  pentagonal cells that exist at each H3 resolution

- `ddbh3_is_h3()`: returns `TRUE` if the H3 cell index is a valid H3
  cell

- `ddbh3_is_res_class_iii()`: returns `TRUE` if the H3 cell belongs to a
  Class III resolution (odd resolutions: 1, 3, 5, 7, 9, 11, 13, 15)

- `ddbh3_is_vertex()`: returns `TRUE` if the index is a valid H3 vertex

- `ddbh3_is_edge()`: returns `TRUE` if the index is a valid H3 directed
  edge

- `ddbh3_is_index()`: returns `TRUE` if the index is any valid H3 index
  (cell, directed edge or vertex)

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

## IS VALID H3 -------------

## Check if h3 indexes are valid
ddbh3_is_h3(points_tbl)
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        ish3 
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff TRUE 
#>  2     2     2  29.2   61.9  C        884221ac65fffff TRUE 
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff TRUE 
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff TRUE 
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff TRUE 
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff TRUE 
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff TRUE 
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff TRUE 
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff TRUE 
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff TRUE 
#> # ℹ more rows

## Check in mutate
points_tbl |>
  mutate(valid = ddbh3_is_h3(h3string))
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        valid
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff TRUE 
#>  2     2     2  29.2   61.9  C        884221ac65fffff TRUE 
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff TRUE 
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff TRUE 
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff TRUE 
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff TRUE 
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff TRUE 
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff TRUE 
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff TRUE 
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff TRUE 
#> # ℹ more rows

## IS PENTAGON -------------

## Check if h3 indexes are pentagons
ddbh3_is_pentagon(points_tbl)
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        ispentagon
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>     
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff FALSE     
#>  2     2     2  29.2   61.9  C        884221ac65fffff FALSE     
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff FALSE     
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff FALSE     
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff FALSE     
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff FALSE     
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff FALSE     
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff FALSE     
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff FALSE     
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff FALSE     
#> # ℹ more rows

## Check in mutate
points_tbl |>
  mutate(is_pent = ddbh3_is_pentagon(h3string))
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        is_pent
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>  
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff FALSE  
#>  2     2     2  29.2   61.9  C        884221ac65fffff FALSE  
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff FALSE  
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff FALSE  
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff FALSE  
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff FALSE  
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff FALSE  
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff FALSE  
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff FALSE  
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff FALSE  
#> # ℹ more rows

## IS CLASS III ------------

## Check if h3 indexes belong to a Class III resolution
ddbh3_is_res_class_iii(points_tbl)
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        isclassiii
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>     
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff FALSE     
#>  2     2     2  29.2   61.9  C        884221ac65fffff FALSE     
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff FALSE     
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff FALSE     
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff FALSE     
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff FALSE     
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff FALSE     
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff FALSE     
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff FALSE     
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff FALSE     
#> # ℹ more rows

## Check across multiple resolutions
ddbh3_lonlat_to_h3(points_tbl, resolution = 7) |>
  ddbh3_is_res_class_iii()
#> # A query:  ?? x 7
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        isclassiii
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <lgl>     
#>  1     1     1 -43.1   16.2  B        87d02dcc1ffffff TRUE      
#>  2     2     2  29.2   61.9  C        874221ac6ffffff TRUE      
#>  3     3     3 -20.7   51.3  C        87a20e8f6ffffff TRUE      
#>  4     4     4  50.9  -14.0  B        87181c6c9ffffff TRUE      
#>  5     5     5 -57.6    8.71 C        87e6cece5ffffff TRUE      
#>  6     6     6 -56.2   21.5  B        87e69d233ffffff TRUE      
#>  7     7     7 -33.7  -17.0  C        87c188075ffffff TRUE      
#>  8     8     8 -32.7  -31.9  A        87c52b36cffffff TRUE      
#>  9     9     9  -7.39  39.0  C        877b6b570ffffff TRUE      
#> 10    10    10  10.0  -89.9  A        876d424aeffffff TRUE      
#> # ℹ more rows

## IS VERTEX ---------------

## Get vertexes first
vertex_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 1)

## Check if indexes are valid vertexes
ddbh3_is_vertex(vertex_tbl)
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string        h3vertex         isvertex
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>            <lgl>   
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 218d02dcc19fffff TRUE    
#>  2     2     2  29.2   61.9  C        884221ac65fffff 2184221ac65fffff TRUE    
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 238a20e8a97fffff TRUE    
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 238181c6c83fffff TRUE    
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 258e6cece43fffff TRUE    
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 258e69d2323fffff TRUE    
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 218c1880751fffff TRUE    
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 238c52b3613fffff TRUE    
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 2187b6b5701fffff TRUE    
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 2186d424ae1fffff TRUE    
#> # ℹ more rows

## Check in mutate (mix of h3 cells and vertexes)
vertex_tbl |>
  mutate(
    cell_valid  = ddbh3_is_h3(h3string),
    vertex_valid = ddbh3_is_vertex(h3vertex)
  )
#> # A query:  ?? x 9
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id    lat    lon category h3string  h3vertex cell_valid vertex_valid
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>     <chr>    <lgl>      <lgl>       
#>  1     1     1 -43.1   16.2  B        88d02dcc… 218d02d… TRUE       TRUE        
#>  2     2     2  29.2   61.9  C        884221ac… 2184221… TRUE       TRUE        
#>  3     3     3 -20.7   51.3  C        88a20e8f… 238a20e… TRUE       TRUE        
#>  4     4     4  50.9  -14.0  B        88181c6c… 238181c… TRUE       TRUE        
#>  5     5     5 -57.6    8.71 C        88e6cece… 258e6ce… TRUE       TRUE        
#>  6     6     6 -56.2   21.5  B        88e69d23… 258e69d… TRUE       TRUE        
#>  7     7     7 -33.7  -17.0  C        88c18807… 218c188… TRUE       TRUE        
#>  8     8     8 -32.7  -31.9  A        88c52b36… 238c52b… TRUE       TRUE        
#>  9     9     9  -7.39  39.0  C        887b6b57… 2187b6b… TRUE       TRUE        
#> 10    10    10  10.0  -89.9  A        886d424a… 2186d42… TRUE       TRUE        
#> # ℹ more rows

## IS EDGE -----------------

## Get directed edges first
edges_tbl <- ddbh3_h3_to_edges(points_tbl)

## Check if indexes are valid directed edges
ddbh3_is_edge(edges_tbl)
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           isedge
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <lgl> 
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff TRUE  
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff TRUE  
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff TRUE  
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff TRUE  
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff TRUE  
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff TRUE  
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff TRUE  
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff TRUE  
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff TRUE  
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff TRUE  
#> # ℹ more rows

## Check in mutate
edges_tbl |>
  mutate(edge_valid = ddbh3_is_edge(h3edge))
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           edge_valid
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <lgl>     
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff TRUE      
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff TRUE      
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff TRUE      
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff TRUE      
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff TRUE      
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff TRUE      
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff TRUE      
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff TRUE      
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff TRUE      
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff TRUE      
#> # ℹ more rows

## IS INDEX ----------------

## Cells and edges are both valid indexes
edges_tbl |>
  ddbh3_is_index(new_column = "cell_index") |>
  ddbh3_is_index(h3 = "h3edge", new_column = "edge_index")
#> # A query:  ?? x 9
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge cell_index edge_index
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>  <lgl>      <lgl>     
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d0… TRUE       TRUE      
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d0… TRUE       TRUE      
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d0… TRUE       TRUE      
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d0… TRUE       TRUE      
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d0… TRUE       TRUE      
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d0… TRUE       TRUE      
#>  7     2     2  29.2  61.9 C        884221ac65fffff 11842… TRUE       TRUE      
#>  8     2     2  29.2  61.9 C        884221ac65fffff 12842… TRUE       TRUE      
#>  9     2     2  29.2  61.9 C        884221ac65fffff 13842… TRUE       TRUE      
#> 10     2     2  29.2  61.9 C        884221ac65fffff 14842… TRUE       TRUE      
#> # ℹ more rows

## Check in mutate
edges_tbl |>
  mutate(valid = ddbh3_is_index(h3edge))
#> # A query:  ?? x 8
#> # Database: DuckDB 2.0.1 [unknown@Linux 7.0.0-1020-azure:R 4.6.2/:memory:]
#>        X    id   lat   lon category h3string        h3edge           valid
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>            <lgl>
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 118d02dcc19fffff TRUE 
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 128d02dcc19fffff TRUE 
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 138d02dcc19fffff TRUE 
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 148d02dcc19fffff TRUE 
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 158d02dcc19fffff TRUE 
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 168d02dcc19fffff TRUE 
#>  7     2     2  29.2  61.9 C        884221ac65fffff 1184221ac65fffff TRUE 
#>  8     2     2  29.2  61.9 C        884221ac65fffff 1284221ac65fffff TRUE 
#>  9     2     2  29.2  61.9 C        884221ac65fffff 1384221ac65fffff TRUE 
#> 10     2     2  29.2  61.9 C        884221ac65fffff 1484221ac65fffff TRUE 
#> # ℹ more rows
```
