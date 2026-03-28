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

## IS VALID H3 -------------

## Check if h3 indexes are valid
ddbh3_is_h3(points_tbl)

## Check in mutate
points_tbl |>
  mutate(valid = ddbh3_is_h3(h3string))

## IS PENTAGON -------------

## Check if h3 indexes are pentagons
ddbh3_is_pentagon(points_tbl)

## Check in mutate
points_tbl |>
  mutate(is_pent = ddbh3_is_pentagon(h3string))

## IS CLASS III ------------

## Check if h3 indexes belong to a Class III resolution
ddbh3_is_res_class_iii(points_tbl)

## Check across multiple resolutions
ddbh3_lonlat_to_h3(points_tbl, resolution = 7) |>
  ddbh3_is_res_class_iii()

## IS VERTEX ---------------

## Get vertexes first
vertex_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 1)

## Check if indexes are valid vertexes
ddbh3_is_vertex(vertex_tbl, h3 = "h3vertex")

## Check in mutate (mix of h3 cells and vertexes)
vertex_tbl |>
  mutate(
    cell_valid  = ddbh3_is_h3(h3string),
    vertex_valid = ddbh3_is_vertex(h3vertex)
  )
} # }
```
