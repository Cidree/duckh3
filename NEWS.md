
# development version

## ENHANCEMENTS

* Functions in vetorized mode automatically parse to UBIGINT when the input is a numeric vector.

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