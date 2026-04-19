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
- [`ddbh3_points_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  [`ddbh3_points_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  : Convert spatial points to H3 cell representations

## H3 hierarchy

Work with H3 resolutions and hierarchy levels

- [`ddbh3_get_resolution()`](https://cidree.github.io/duckh3/reference/ddbh3_get_resolution.md)
  : Get the resolution of H3 cell indexes
- [`ddbh3_get_child_pos()`](https://cidree.github.io/duckh3/reference/ddbh3_get_child_pos.md)
  : Get the position of an H3 cell within its parent
- [`ddbh3_get_parent()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_n_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  [`ddbh3_get_center_child()`](https://cidree.github.io/duckh3/reference/ddbh3_get_hierarchy.md)
  : Get parent and children H3 cells
- [`ddbh3_get_icosahedron_faces()`](https://cidree.github.io/duckh3/reference/ddbh3_get_icosahedron_faces.md)
  : Get the icosahedron faces of H3 cell indexes

## H3 properties

Check properties of H3 cell indexes

- [`ddbh3_is_pentagon()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_res_class_iii()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  [`ddbh3_is_vertex()`](https://cidree.github.io/duckh3/reference/ddbh3_is.md)
  : Check properties of H3 cell indexes

## H3 vertices

Extract and convert H3 cell vertices to spatial representations

- [`ddbh3_h3_to_vertex()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_lon()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_lat()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_h3_to_vertexes()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  [`ddbh3_vertex_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_vertex.md)
  : Convert H3 cell indexes to vertex representations
