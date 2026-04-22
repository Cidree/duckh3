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
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_h3(
  x,
  h3 = "h3string",
  new_column = "ish3",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_res_class_iii(
  x,
  h3 = "h3string",
  new_column = "isclassiii",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_is_vertex(
  x,
  h3vertex = "h3vertex",
  new_column = "isvertex",
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

The functions check different properties of H3 cell indexes, all
returning a logical column:

- `ddbh3_is_pentagon()`: returns `TRUE` if the H3 cell is one of the 12
  pentagonal cells that exist at each H3 resolution

- `ddbh3_is_h3()`: returns `TRUE` if the H3 cell index is a valid H3
  cell

- `ddbh3_is_res_class_iii()`: returns `TRUE` if the H3 cell belongs to a
  Class III resolution (odd resolutions: 1, 3, 5, 7, 9, 11, 13, 15)

- `ddbh3_is_vertex()`: returns `TRUE` if the index is a valid H3 vertex

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
#> # Source:   table<temp_view_60e4ab24_5b1e_41bd_82c2_9b23ef480f9d> [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   table<temp_view_f2e98b41_201e_42e9_a003_cf9069915d01> [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   table<temp_view_4522a3db_6c1b_4004_9ee7_ecfdbc6c3844> [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   table<temp_view_9aca75ae_512c_498d_a946_dab09462b9f5> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        h3string_1      isclassiii
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>           <lgl>     
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 87d02dcc1ffffff FALSE     
#>  2     2     2  29.2   61.9  C        884221ac65fffff 874221ac6ffffff FALSE     
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 87a20e8f6ffffff FALSE     
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 87181c6c9ffffff FALSE     
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 87e6cece5ffffff FALSE     
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 87e69d233ffffff FALSE     
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 87c188075ffffff FALSE     
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 87c52b36cffffff FALSE     
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 877b6b570ffffff FALSE     
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 876d424aeffffff FALSE     
#> # ℹ more rows

## IS VERTEX ---------------

## Get vertexes first
vertex_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 1)

## Check if indexes are valid vertexes
ddbh3_is_vertex(vertex_tbl, h3 = "h3vertex")
#> # Source:   table<temp_view_2cc5f7a1_858d_41a5_a51f_53b3ff8eb7b8> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
#> # Source:   SQL [?? x 9]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1011-azure:R 4.5.3/:memory:]
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
```
