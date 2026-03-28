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
if (FALSE) { # \dontrun{
## Load needed packages
library(duckh3)
library(dplyr)

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

## Add with mutate
points_tbl |> 
  mutate(parent4 = ddbh3_get_parent(h3string, 4))

## GET CHILDREN ----------

## Get level 9 children
children_9_tbl <- ddbh3_get_children(points_tbl, resolution = 9)

## Get level 9 children in a nested list
children_9_nested_tbl <- ddbh3_get_children(points_tbl, resolution = 9, nested = TRUE)

## Add with mutate (nested)
points_tbl |> 
  mutate(children9 = ddbh3_get_children(h3string, 9))

## Add with mutate (unnested)
points_tbl |> 
  mutate(children9 = ddbh3_get_children(h3string, 9)) |> 
  mutate(children9 = unnest(children9))

## GET CENTER CHILD ------

## Get the center child of res 10 (1 child per row)
center_child_10_tbl <- ddbh3_get_center_child(points_tbl, resolution = 10)

## Add with mutate
points_tbl |> 
  mutate(center = ddbh3_get_center_child(h3string, 9))

## NUMBER OF CHILDREN -----

## How many children of level 10 does each level 8 have?
n_children_tbl <- ddbh3_get_n_children(points_tbl, resolution = 10)

## Add with mutate
points_tbl |> 
  mutate(n_children = ddbh3_get_n_children(h3string, 15))

} # }
```
