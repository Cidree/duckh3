# Package index

## Setup and Connection

Manage connections with H3 extension

- [`ddbh3_create_conn()`](https://cidree.github.io/duckh3/reference/ddbh3_create_conn.md)
  : Create a DuckDB connection with spatial and h3 extensions
- [`ddbh3_default_conn()`](https://cidree.github.io/duckh3/reference/ddbh3_default_conn.md)
  : Get or create default DuckDB connection

## H3 representations

Converts from/to different H3 representations

- [`ddbh3_h3_to_lon()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_h3_to_lat()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_h3_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_strings_to_bigint()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_bigint_to_strings()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_h3_to_points()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  : Convert H3 string or UBIGINT indexes to other representations
- [`ddbh3_lonlat_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_lonlat_to.md)
  [`ddbh3_lonlat_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_lonlat_to.md)
  : Convert longitude and latitude to H3 cell representations
- [`ddbh3_polygons_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
  [`ddbh3_lines_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
  [`ddbh3_polygons_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
  [`ddbh3_lines_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
  : Convert polygon or linestring geometries to H3 cell representations
- [`ddbh3_points_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  [`ddbh3_points_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  : Convert spatial points to H3 cell representations

## H3 hierarchy

Work with H3 resolutions and hierarchy levels

- [`ddbh3_get_base_cell_number()`](https://cidree.github.io/duckh3/reference/ddbh3_get_base_cell_number.md)
  : Get the base cell number of an H3 cell
- [`ddbh3_digits_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_digits_to_h3.md)
  : Build H3 cells from a base cell and digits
- [`ddbh3_get_resolution()`](https://cidree.github.io/duckh3/reference/ddbh3_get_resolution.md)
  : Get the resolution of H3 cell indexes
- [`ddbh3_get_child_pos()`](https://cidree.github.io/duckh3/reference/ddbh3_get_child_pos.md)
  : Get the position of an H3 cell within its parent
- [`ddbh3_child_pos_to_cell()`](https://cidree.github.io/duckh3/reference/ddbh3_child_pos_to_cell.md)
  : Get an H3 child cell from a parent and child position
- [`ddbh3_get_parent()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_n_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_center_child()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  : Get parent and children H3 cells
- [`ddbh3_get_icosahedron_faces()`](https://cidree.github.io/duckh3/reference/ddbh3_get_icosahedron_faces.md)
  : Get the icosahedron faces of H3 cell indexes
- [`ddbh3_compact()`](https://cidree.github.io/duckh3/reference/ddbh3_compact.md)
  [`ddbh3_uncompact()`](https://cidree.github.io/duckh3/reference/ddbh3_compact.md)
  : Compact and uncompact sets of H3 cells

## H3 metrics

Measure areas, lengths and distances

- [`ddbh3_get_area()`](https://cidree.github.io/duckh3/reference/ddbh3_get_area.md)
  : Get the area of H3 cells
- [`ddbh3_get_hexagon_area_avg()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hexagon_avg.md)
  [`ddbh3_get_hexagon_edge_length_avg()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hexagon_avg.md)
  : Get the average area and edge length of H3 hexagons
- [`ddbh3_great_circle_distance()`](https://cidree.github.io/duckh3/reference/ddbh3_great_circle_distance.md)
  : Get the great circle distance between two points

## H3 neighborhood

Work with neighbors of H3 cells

- [`ddbh3_grid_disk()`](https://cidree.github.io/duckh3/reference/ddbh3_grid_disk.md)
  [`ddbh3_grid_disk_distances()`](https://cidree.github.io/duckh3/reference/ddbh3_grid_disk.md)
  [`ddbh3_grid_ring()`](https://cidree.github.io/duckh3/reference/ddbh3_grid_disk.md)
  : Get H3 grid neighborhoods (disks, rings, and distances)
- [`ddbh3_grid_distance()`](https://cidree.github.io/duckh3/reference/ddbh3_grid_distance.md)
  : Get the grid distance between two H3 cells
- [`ddbh3_grid_path_cells()`](https://cidree.github.io/duckh3/reference/ddbh3_grid_path_cells.md)
  : Find a grid path connecting two H3 cells
- [`ddbh3_is_neighbor()`](https://cidree.github.io/duckh3/reference/ddbh3_is_neighbor.md)
  : Check if two H3 cells are neighbors
- [`ddbh3_h3_to_local_ij()`](https://cidree.github.io/duckh3/reference/ddbh3_local_ij.md)
  [`ddbh3_local_ij_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_local_ij.md)
  : Work with H3 local IJ coordinates
- [`ddbh3_max_grid_disk_size()`](https://cidree.github.io/duckh3/reference/ddbh3_max_grid_disk_size.md)
  : Get the maximum grid disk size for a given distance k

## H3 properties

Check properties of H3 cell indexes

- [`ddbh3_is_pentagon()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_res_class_iii()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_vertex()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_edge()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_index()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  : Check properties of H3 cell indexes

## H3 vertices

Extract and convert H3 cell vertices to spatial representations

- [`ddbh3_h3_to_vertex()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_lon()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_lat()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_h3_to_vertexes()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  : Convert H3 cell indexes to vertex representations

## H3 directed edges

Create H3 directed edges and convert them to cells, lengths and lines

- [`ddbh3_h3_to_edge()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_h3_to_edges()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_edge_to_origin()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_edge_to_destination()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_edge_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_reverse_edge()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_get_edge_length()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  [`ddbh3_edge_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_edge.md)
  : Work with H3 directed edges
