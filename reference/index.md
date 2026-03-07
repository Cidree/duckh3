# Package index

## Setup and Connection

Manage connections with H3 extension

- [`ddbh3_create_conn()`](https://cidree.github.io/duckh3/reference/ddbh3_create_conn.md)
  : Create a DuckDB connection with spatial and h3 extensions

## H3 representations

Converts from/to different H3 representations

- [`ddbh3_h3_to_lon()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_h3_to_lat()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_h3_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_strings_to_bigint()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  [`ddbh3_bigint_to_strings()`](https://cidree.github.io/duckh3/reference/ddbh3_h3_to.md)
  : Convert H3 string or UBIGINT indexes to other representations
- [`ddbh3_lonlat_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_lonlat_to.md)
  [`ddbh3_lonlat_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_lonlat_to.md)
  : Convert longitude and latitude to H3 cell representations
- [`ddbh3_points_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  [`ddbh3_points_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_points_to.md)
  : Convert spatial points to H3 cell representations

## H3 hierarchy

Work with H3 resolutions and parent/child cells

- [`ddbh3_get_resolution()`](https://cidree.github.io/duckh3/reference/ddbh3_get_resolution.md)
  : Get the resolution of H3 cell indexes
- [`ddbh3_get_n_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_n_children.md)
  : Get the number of children of H3 cell indexes
- [`ddbh3_get_children()`](https://cidree.github.io/duckh3/reference/ddbh3_get_children.md)
  : Get the children H3 cells of H3 indexes
- [`ddbh3_get_parent()`](https://cidree.github.io/duckh3/reference/ddbh3_get_parent.md)
  : Get the parent H3 cell of H3 indexes
