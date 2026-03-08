# duckh3

> 🦆 **{duckh3} is a work in progress!** We’re actively building and
> refining the package — function names, arguments, and behaviour may
> change as the API matures. Feedback and bug reports are very welcome
> via [GitHub Issues](https://github.com/Cidree/duckh3/issues). Thanks
> for being an early user! 🙏

**{duckh3}** provides fast, memory-efficient functions for analysing and
manipulating large spatial and non-spatial datasets using the [H3
hierarchical indexing system](https://h3geo.org/) in R. It bridges
[DuckDB’s H3
extension](https://duckdb.org/community_extensions/extensions/h3) with
R’s data and spatial ecosystems — in particular **{duckspatial}**,
**{dplyr}**, and **{sf}** — so you can leverage DuckDB’s analytical
power without leaving your familiar R workflow.

### How it works

{duckh3} operates on regular R data frames, `tibble`s, `dbplyr` lazy
tables, and `duckspatial_df` objects. Unlike purely spatial workflows,
H3 operations do not require your data to be spatial. Any table with
longitude/latitude columns, or an existing H3 index column, is a valid
starting point.

When a DuckDB connection is used, all H3 operations run inside that
connection with the H3 extension enabled, letting DuckDB apply its own
query optimisations before any data reaches R. Results are returned
lazily and only materialised when you explicitly collect them.

In addition, {duckh3} registers a set of **DuckDB macros** on the
default connection at load time, making H3 functions available directly
inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
on lazy tables — no wrapper function needed. Note that they **only work
with lazy tables**, not with regular data frames.

### Naming conventions

All functions follow the `ddbh3_*()` prefix (*DuckDB H3*), structured
around what they do:

- `ddbh3_lonlat_to_*()` — from longitude/latitude coordinates to H3
  representations
- `ddbh3_points_to_*()` — from spatial point geometries to H3
  representations
- `ddbh3_get_*()` — retrieve H3 cell properties (resolution, parent,
  children, vertices…)
- `ddbh3_is_*()` — check properties of H3 indexes (valid, pentagon,
  Class III…)
- `ddbh3_h3_to_*()` — convert H3 cells to other representations

## Installation

Install the latest GitHub version:

``` r
# install.packages("pak")
pak::pak("Cidree/duckh3")
```

Install the development version (may be unstable):

``` r
pak::pak("Cidree/duckh3@dev")
```

## Core idea: flexible H3 workflows

A central design principle of {duckh3} is that the same H3 operation can
be used in different ways depending on how your data is stored and what
output format you need.

### Format conversions

| Function family  | Output                             |
|------------------|------------------------------------|
| `*_to_h3()`      | H3 index as string or `UBIGINT`    |
| `*_to_spatial()` | H3 cell as spatial hexagon polygon |
| `*_to_lon()`     | Longitude of H3 cell centroid      |
| `*_to_lat()`     | Latitude of H3 cell centroid       |

### H3 hierarchy

| Function                                                                                       | Returns                                  |
|------------------------------------------------------------------------------------------------|------------------------------------------|
| [`ddbh3_get_resolution()`](https://cidree.github.io/duckh3/reference/ddbh3_get_resolution.md)  | Resolution of each H3 cell               |
| [`ddbh3_get_parent()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)       | Parent cell at a coarser resolution      |
| [`ddbh3_get_center_child()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md) | Center child cell at a finer resolution  |
| [`ddbh3_get_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)     | All children cells at a finer resolution |
| [`ddbh3_get_n_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)   | Number of children at a finer resolution |
| [`ddbh3_get_child_pos()`](https://cidree.github.io/duckh3/reference/ddbh3_get_child_pos.md)    | Position of a cell within its parent     |

### H3 properties

| Function                                                                            | Returns                                       |
|-------------------------------------------------------------------------------------|-----------------------------------------------|
| [`ddbh3_is_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)            | `TRUE` if the index is a valid H3 cell        |
| [`ddbh3_is_pentagon()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)      | `TRUE` if the cell is one of the 12 pentagons |
| [`ddbh3_is_res_class_iii()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md) | `TRUE` if the cell is at an odd resolution    |
| [`ddbh3_is_vertex()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)        | `TRUE` if the index is a valid H3 vertex      |

Inputs can be plain R data frames, lazy `dbplyr` tables, `sf` objects,
or `duckspatial_df` objects, making {duckh3} easy to integrate into both
non-spatial and spatial pipelines.

## Contributing

Bug reports, feature requests, and pull requests are very welcome!

- [Raise an issue](https://github.com/Cidree/duckh3/issues)
- [Open a pull request](https://github.com/Cidree/duckh3/pulls)
