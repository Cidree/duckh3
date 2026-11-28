
# Development version

* Updated the `duckdb` dependency to v2.0.0 See <https://r.duckdb.org/news/index.html#duckdb-200>.

## BUG FIXES

* `ddbh3_default_conn()` no longer reuses a default connection created by `duckspatial` with `bigint = "numeric"`, which silently rounded UBIGINT H3 indexes. It now warns and replaces it with an `integer64` connection.
* Column-name arguments (`new_column`, `h3`, `h3vertex`, `lon`, `lat`) and the geometry column name are now quoted as SQL identifiers, so names with spaces or quotes work and SQL expressions passed as column names are no longer executed.
* When the input already has a column named like `new_column`, the result now replaces that column. Before, the result was added as `<new_column>_1` and the original column kept its old values.
* Writing the result to the input table itself (`name` equal to the source table and `overwrite = TRUE`) no longer deletes the source table: the result is now built in a staging table and swapped in place.
* `ddbh3_create_conn()` and `ddbh3_default_conn()` set `geometry_always_xy = false`, which DuckDB >= 2.0 requires before spheroid functions such as `duckspatial::ddbs_area()` can run on H3 geometries. This keeps the pre-2.0 axis convention that duckspatial's measure functions are written for.
* `ddbh3_create_conn()` now registers the `ddbh3_*` macros, so they work inside `dplyr::mutate()` on user-created connections.
* `ddbh3_default_conn(create = FALSE)` no longer errors when no default connection exists.
* `ddbh3_vertex_to_lon()`, `ddbh3_vertex_to_lat()` and `ddbh3_is_vertex()` no longer reject valid H3 vertexes in vectorized mode, and `ddbh3_is_vertex()` returns `FALSE` for invalid input instead of erroring.
* `ddbh3_create_conn()` and `ddbh3_default_conn()` set `geometry_always_xy = true`, which DuckDB >= 2.0 requires before spheroid functions such as `duckspatial::ddbs_area()` can run on H3 geometries. This keeps the pre-2.0 axis convention that duckspatial's measure functions are written for.
* `ddbh3_child_pos_to_cell()` no longer errors when the child position column is stored as a double (e.g. `data.frame(h3child_pos = 0)`).

## ENHANCEMENTS

* Remove arrow lambda syntax for compatibility with DuckDB v2.0 (#6).

* The `@returns` documentation now states that spatial outputs are returned as `sf` with `mode = "sf"`, that `*_to_spatial()` functions and `ddbh3_h3_to_points()` always return spatial output, and that `mode` is ignored for non-spatial results (#10).

* Vectorized mode is up to ~40x faster: input validation and evaluation now run in a single query, and the default connection is no longer re-initialised on every call. The h3 extension check is cached for the default connection.

## NEW FEATURES

* All functions gain a `mode` argument that can be set to "sf" or "duckspatial" to return the output in that format. Alternatively, the user can use `duckspatial::ddbs_options()` to set the mode globally.

* H3 directed edges: `ddbh3_h3_to_edge()`, `ddbh3_h3_to_edges()`, `ddbh3_edge_to_origin()`, `ddbh3_edge_to_destination()`, `ddbh3_edge_to_h3()`, `ddbh3_reverse_edge()`, `ddbh3_get_edge_length()` and `ddbh3_edge_to_spatial()` create directed edges from H3 cells and convert them to cells, lengths and lines. They also work inside `dplyr::mutate()` on lazy tables (except `ddbh3_edge_to_spatial()`).

* `ddbh3_compact()` and `ddbh3_uncompact()`: compact a set of H3 cells into the smallest set of cells covering the same area (optionally per group with `by`), and uncompact cells back to a single resolution. `ddbh3_compact()` also works inside `dplyr::summarise()`, and `ddbh3_uncompact()` inside `dplyr::mutate()` on list columns.

* `ddbh3_h3_to_local_ij()` and `ddbh3_local_ij_to_h3()` convert H3 cells to local IJ coordinates relative to an origin cell, and back. They also work inside `dplyr::mutate()` on lazy tables.

* `ddbh3_is_index()` checks if an index is any valid H3 index (cell, directed edge or vertex), and `ddbh3_digits_to_h3()` builds H3 cells from a base cell and a list of digits. They also work inside `dplyr::mutate()` on lazy tables.

* H3 metrics: `ddbh3_get_area()` gets the area of H3 cells, `ddbh3_great_circle_distance()` gets the great circle distance between two points, and `ddbh3_get_hexagon_area_avg()` and `ddbh3_get_hexagon_edge_length_avg()` get the average hexagon area and edge length at one or more resolutions. They also work inside `dplyr::mutate()` on lazy tables.

* `ddbh3_is_edge()`: check if an index is a valid H3 directed edge.

* `ddbh3_is_neighbor()`: check if two H3 cells are neighbors.

* `ddbh3_grid_path_cells()`: find a grid path connecting two H3 cells.

* `ddbh3_grid_distance()`: get the grid distance between two H3 cells.

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