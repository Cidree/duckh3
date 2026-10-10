# Changelog

## duckh3 0.2.0

### BUILD

- Requires DuckDB \>= 1.5.5

### ENHANCEMENTS

- Functions in vetorized mode automatically parse to UBIGINT when the
  input is a numeric vector.

- Error message on wrong CRS is now displayed correctly
  ([\#3](https://github.com/Cidree/duckh3/issues/3)).

### NEW FEATURES

- New functions to convert polygon and linestring geometries to H3 cells
  ([\#2](https://github.com/Cidree/duckh3/issues/2)):
  - [`ddbh3_polygons_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
    /
    [`ddbh3_lines_to_h3()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
    add a list column with the H3 cells intersecting each feature
    (string or `UBIGINT`).
  - [`ddbh3_polygons_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
    /
    [`ddbh3_lines_to_spatial()`](https://cidree.github.io/duckh3/reference/ddbh3_geom_to.md)
    return one row per intersecting cell, with geometry replaced by the
    cell hexagon boundary.
  - Polygons use DuckDB’s experimental polygon polyfill (`overlap`
    containment by default); lines are polyfilled via a
    buffer-then-exact-trim strategy since they have no native polyfill
    (`buffer_scale` argument).

## duckh3 0.1.0

CRAN release: 2026-04-24

Learn more about this release
[here](https://adrian-cidre.com/posts/016_duckh3/).

- Initial CRAN submission.
