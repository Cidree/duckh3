# Get parent and children H3 cells

Get the parent or children H3 cells of H3 cell indexes stored as strings
or unsigned 64-bit integers (`UBIGINT`) at a specified resolution:
`ddbh3_get_parent()`, `ddbh3_get_center_child()`,
`ddbh3_get_children()`, and `ddbh3_get_n_children()`.

## Usage

``` r
ddbh3_get_parent(
  x,
  resolution = 8,
  h3 = "h3string",
  new_column = "h3parent",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_get_children(
  x,
  resolution = 8,
  h3 = "h3string",
  new_column = "h3children",
  conn = NULL,
  name = NULL,
  nested = FALSE,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_get_n_children(
  x,
  resolution = 8,
  h3 = "h3string",
  new_column = "h3n_children",
  conn = NULL,
  name = NULL,
  overwrite = FALSE,
  quiet = FALSE
)

ddbh3_get_center_child(
  x,
  resolution = 8,
  h3 = "h3string",
  new_column = "h3center_child",
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

- resolution:

  A number specifying the resolution level of the H3 string (between 0
  and 15)

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

The four functions differ in the type of related cell they retrieve:

- `ddbh3_get_parent()` returns the parent cell at a coarser resolution

- `ddbh3_get_center_child()` returns the center child cell at a finer
  resolution

- `ddbh3_get_children()` returns all children cells at a finer
  resolution

- `ddbh3_get_n_children()` returns the number of children cells at a
  finer resolution, without computing them

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

## GET PARENTS ----------

## Get resolution-7 parent
points_parent_tbl <- ddbh3_get_parent(points_tbl, resolution = 7)

## Check the resolution
ddbh3_get_resolution(
  points_parent_tbl,
  h3 = "h3parent"
)
#> # Source:   table<temp_view_616ea316_ab85_403a_8f16_8b941296f99a> [?? x 8]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        h3parent      h3resolution
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>                <int>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 87d02dcc1fff…            7
#>  2     2     2  29.2   61.9  C        884221ac65fffff 874221ac6fff…            7
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 87a20e8f6fff…            7
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 87181c6c9fff…            7
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 87e6cece5fff…            7
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 87e69d233fff…            7
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 87c188075fff…            7
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 87c52b36cfff…            7
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 877b6b570fff…            7
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 876d424aefff…            7
#> # ℹ more rows

## Add with mutate
points_tbl |> 
  mutate(parent4 = ddbh3_get_parent(h3string, 4))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        parent4        
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>          
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 84d02ddffffffff
#>  2     2     2  29.2   61.9  C        884221ac65fffff 844221bffffffff
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 84a20e9ffffffff
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 84181c7ffffffff
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 84e6cedffffffff
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 84e69d3ffffffff
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 84c1881ffffffff
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 84c52b3ffffffff
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 847b6b5ffffffff
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 846d425ffffffff
#> # ℹ more rows

## GET CHILDREN ----------

## Get level 9 children
children_9_tbl <- ddbh3_get_children(points_tbl, resolution = 9)

## Get level 9 children in a nested list
children_9_nested_tbl <- ddbh3_get_children(points_tbl, resolution = 9, nested = TRUE)

## Add with mutate (nested)
points_tbl |> 
  mutate(children9 = ddbh3_get_children(h3string, 9))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        children9
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <list>   
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff <chr [7]>
#>  2     2     2  29.2   61.9  C        884221ac65fffff <chr [7]>
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff <chr [7]>
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff <chr [7]>
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff <chr [7]>
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff <chr [7]>
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff <chr [7]>
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff <chr [7]>
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff <chr [7]>
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff <chr [7]>
#> # ℹ more rows

## Add with mutate (unnested)
points_tbl |> 
  mutate(children9 = ddbh3_get_children(h3string, 9)) |> 
  mutate(children9 = unnest(children9))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id   lat   lon category h3string        children9      
#>    <int> <int> <dbl> <dbl> <chr>    <chr>           <chr>          
#>  1     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc183ffff
#>  2     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc187ffff
#>  3     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc18bffff
#>  4     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc18fffff
#>  5     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc193ffff
#>  6     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc197ffff
#>  7     1     1 -43.1  16.2 B        88d02dcc19fffff 89d02dcc19bffff
#>  8     2     2  29.2  61.9 C        884221ac65fffff 894221ac643ffff
#>  9     2     2  29.2  61.9 C        884221ac65fffff 894221ac647ffff
#> 10     2     2  29.2  61.9 C        884221ac65fffff 894221ac64bffff
#> # ℹ more rows

## GET CENTER CHILD ------

## Get the center child of res 10 (1 child per row)
center_child_10_tbl <- ddbh3_get_center_child(points_tbl, resolution = 10)

## Add with mutate
points_tbl |> 
  mutate(center = ddbh3_get_center_child(h3string, 9))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        center         
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>           <chr>          
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff 89d02dcc183ffff
#>  2     2     2  29.2   61.9  C        884221ac65fffff 894221ac643ffff
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff 89a20e8f683ffff
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff 89181c6c943ffff
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff 89e6cece5c3ffff
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff 89e69d233c3ffff
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff 89c18807503ffff
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff 89c52b36c43ffff
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff 897b6b57003ffff
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff 896d424ae03ffff
#> # ℹ more rows

## NUMBER OF CHILDREN -----

## How many children of level 10 does each level 8 have?
n_children_tbl <- ddbh3_get_n_children(points_tbl, resolution = 10)

## Add with mutate
points_tbl |> 
  mutate(n_children = ddbh3_get_n_children(h3string, 15))
#> # Source:   SQL [?? x 7]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3/:memory:]
#>        X    id    lat    lon category h3string        n_children
#>    <int> <int>  <dbl>  <dbl> <chr>    <chr>              <int64>
#>  1     1     1 -43.1   16.2  B        88d02dcc19fffff     823543
#>  2     2     2  29.2   61.9  C        884221ac65fffff     823543
#>  3     3     3 -20.7   51.3  C        88a20e8f69fffff     823543
#>  4     4     4  50.9  -14.0  B        88181c6c95fffff     823543
#>  5     5     5 -57.6    8.71 C        88e6cece5dfffff     823543
#>  6     6     6 -56.2   21.5  B        88e69d233dfffff     823543
#>  7     7     7 -33.7  -17.0  C        88c1880751fffff     823543
#>  8     8     8 -32.7  -31.9  A        88c52b36c5fffff     823543
#>  9     9     9  -7.39  39.0  C        887b6b5701fffff     823543
#> 10    10    10  10.0  -89.9  A        886d424ae1fffff     823543
#> # ℹ more rows
```
