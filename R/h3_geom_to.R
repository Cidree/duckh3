#' Convert polygon or linestring geometries to H3 cell representations
#'
#' Convert polygon or linestring geometries into the H3 cells that
#' intersect them, at a specified resolution. Input must be a
#' `duckspatial_df`, `sf`, or table with POLYGON/MULTIPOLYGON or
#' LINESTRING/MULTILINESTRING geometries
#'
#' @template x
#' @template resolution
#' @template new_column
#' @param h3_format Character. Output format for the H3 cell indexes stored
#' in `new_column`. Either `"string"` (default) or `"bigint"`. Only used in
#' `ddbh3_polygons_to_h3()` and `ddbh3_lines_to_h3()`.
#' @param containment Character. Polyfill containment mode: `"overlap"`
#' (default), `"full"`, `"center"`, or `"overlap_bbox"`. See the DuckDB H3
#' extension documentation for details on each mode.
#' @param buffer_scale Numeric. Line-buffer size as a multiple of one cell
#' footprint (default `1`). Only used in `ddbh3_lines_to_h3()` and
#' `ddbh3_lines_to_spatial()`, since a line has zero width and therefore no
#' native polyfill: candidate cells are found by buffering the line, and the
#' result is trimmed back to the exact intersecting set. Larger values are
#' safer (slower) but never change correctness.
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#'
#' @details
#' The four functions differ in the input geometry family and output format:
#' * `ddbh3_polygons_to_h3()` / `ddbh3_lines_to_h3()` add a list column with
#'   the H3 cells intersecting each feature, as strings or `UBIGINT`
#' * `ddbh3_polygons_to_spatial()` / `ddbh3_lines_to_spatial()` return one row
#'   per (feature, intersecting cell), with the geometry replaced by the H3
#'   cell hexagon boundary
#'
#' Polygons are polyfilled directly with DuckDB's experimental polygon
#' polyfill using the `overlap` containment mode by default, so boundary
#' cells are included. Lines have no native polyfill: a buffer is built
#' around the line (sized from one cell's footprint in degrees, so it stays
#' latitude-correct), the buffer is polyfilled, and the candidate cells are
#' trimmed back to the exact intersecting set with `ST_Intersects` against
#' the original line.
#'
#' @template returns_tbl
#'
#' @name ddbh3_geom_to
#' @rdname ddbh3_geom_to
#' @aliases ddbh3_polygons_to_h3 ddbh3_polygons_to_spatial ddbh3_lines_to_h3 ddbh3_lines_to_spatial
#'
#' @examples
#' \donttest{
#' ## Load needed packages
#' library(duckh3)
#' library(duckspatial)
#' library(sf)
#'
#' ## Setup the default connection with h3 and spatial extensions
#' ddbh3_default_conn(threads = 1)
#'
#' ## Build a small polygon and a small line in EPSG:4326
#' poly_sf <- st_as_sf(
#'   st_sfc(
#'     st_polygon(list(rbind(
#'       c(-0.5, -0.5), c(0.5, -0.5), c(0.5, 0.5), c(-0.5, 0.5), c(-0.5, -0.5)
#'     ))),
#'     crs = 4326
#'   )
#' )
#'
#' line_sf <- st_as_sf(
#'   st_sfc(
#'     st_linestring(rbind(c(-0.5, -0.5), c(0.5, 0.5))),
#'     crs = 4326
#'   )
#' )
#'
#' ## POLYGONS TO H3 -------------
#'
#' ## Add a list column with the intersecting h3 strings
#' poly_h3_tbl <- ddbh3_polygons_to_h3(poly_sf, resolution = 4)
#'
#' ## POLYGONS TO SPATIAL --------
#'
#' ## One row per intersecting cell, geometry = cell hexagon
#' poly_cells_ddbs <- ddbh3_polygons_to_spatial(poly_sf, resolution = 4)
#'
#' ## LINES TO H3 ----------------
#'
#' line_h3_tbl <- ddbh3_lines_to_h3(line_sf, resolution = 4)
#'
#' ## LINES TO SPATIAL -----------
#'
#' line_cells_ddbs <- ddbh3_lines_to_spatial(line_sf, resolution = 4)
#' }
NULL





#' @rdname ddbh3_geom_to
#' @export
ddbh3_polygons_to_spatial <- function(
    x,
    resolution,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    containment = "overlap"
) {

  template_h3_geom_to_spatial(
    x           = x,
    resolution  = resolution,
    conn        = conn,
    name        = name,
    overwrite   = overwrite,
    quiet       = quiet,
    containment = containment,
    geom_family = "POLYGON"
  )

}





#' @rdname ddbh3_geom_to
#' @export
ddbh3_lines_to_spatial <- function(
    x,
    resolution,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    containment = "overlap",
    buffer_scale = 1
) {

  template_h3_geom_to_spatial(
    x            = x,
    resolution   = resolution,
    conn         = conn,
    name         = name,
    overwrite    = overwrite,
    quiet        = quiet,
    containment  = containment,
    buffer_scale = buffer_scale,
    geom_family  = "LINESTRING"
  )

}





#' @rdname ddbh3_geom_to
#' @export
ddbh3_polygons_to_h3 <- function(
    x,
    resolution,
    new_column = "h3string",
    h3_format = "string",
    containment = "overlap",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  template_h3_geom_to_h3(
    x           = x,
    resolution  = resolution,
    new_column  = new_column,
    h3_format   = h3_format,
    containment = containment,
    conn        = conn,
    name        = name,
    overwrite   = overwrite,
    quiet       = quiet,
    geom_family = "POLYGON"
  )

}





#' @rdname ddbh3_geom_to
#' @export
ddbh3_lines_to_h3 <- function(
    x,
    resolution,
    new_column = "h3string",
    h3_format = "string",
    containment = "overlap",
    buffer_scale = 1,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  template_h3_geom_to_h3(
    x            = x,
    resolution   = resolution,
    new_column   = new_column,
    h3_format    = h3_format,
    containment  = containment,
    buffer_scale = buffer_scale,
    conn         = conn,
    name         = name,
    overwrite    = overwrite,
    quiet        = quiet,
    geom_family  = "LINESTRING"
  )

}