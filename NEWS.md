
# Development version

## ENHANCEMENTS

* Remove arrow lambda syntax for compatibility with DuckDB v2.0 (#6).

## NEW FEATURES

* `ddbh3_grid_disk()`, `dbh3_grid_disk_distances()`, `ddbh3_grid_ring()`: get H3 grid neighborhoods (disks, rings, and distances).

* `ddbh3_max_grid_disk_size()`: get the maximum grid disk size for a given distance k.

* `ddbh3_child_pos_to_cell()`: get an H3 child cell from a parent and child position.

* `ddbh3_get_base_cell_number()`: get the base cell number of an H3 cell.


# duckh3 0.2.0

## BUILD

* Requires DuckDB >= 1.5.6

* Requires `duckspatial` >= 1.3.0

## ENHANCEMENTS

* Functions in vetorized mode automatically parse to UBIGINT when the input is a numeric vector.

* Error message on wrong CRS is now displayed correctly (#3).

## NEW FEATURES

* New functions to convert polygon and linestring geometries to H3 cells (#2):
  * `ddbh3_polygons_to_h3()` / `ddbh3_lines_to_h3()` add a list column with
    the H3 cells intersecting each feature (string or `UBIGINT`).
  * `ddbh3_polygons_to_spatial()` / `ddbh3_lines_to_spatial()` return one row
    per intersecting cell, with geometry replaced by the cell hexagon
    boundary.
  * Polygons use DuckDB's experimental polygon polyfill (`overlap`
    containment by default); lines are polyfilled via a buffer-then-exact-trim
    strategy since they have no native polyfill (`buffer_scale` argument).


# duckh3 0.1.0

Learn more about this release [here](https://adrian-cidre.com/posts/016_duckh3/){target="_blank"}.

-   Initial CRAN submission.