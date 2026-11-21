#' Get the area of H3 cells
#'
#' Get the exact area of H3 cell indexes stored as strings or unsigned 64-bit
#' integers
#'
#' @template x
#' @template h3
#' @param unit Character. Unit of the area. One of `"m^2"` (default), `"km^2"`
#'   or `"rads^2"`.
#' @param new_column Name of the new column to create on the input data.
#'   Defaults to `"h3area"`.
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @details
#' The area is computed for each individual cell, so it differs from the
#' average cell area at a resolution returned by
#' [ddbh3_get_hexagon_area_avg()]. Cells of the same resolution have different
#' areas depending on their location on the globe.
#'
#' @template returns_tbl
#'
#' @seealso [ddbh3_get_hexagon_area_avg()], [ddbh3_get_edge_length()]
#' @export
#'
#' @examples
#' ## Load needed packages
#' library(duckh3)
#' library(dplyr)
#'
#' ## Setup the default connection with h3 and spatial extensions
#' ## This is a mandatory step to use duckh3 functions
#' ddbh3_default_conn(threads = 1)
#'
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#'
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)
#'
#' ## Area of the cells in square meters
#' ddbh3_get_area(points_tbl)
#'
#' ## Area in square kilometers
#' ddbh3_get_area(points_tbl, unit = "km^2")
#'
#' ## Inside mutate
#' points_tbl |>
#'   mutate(area = ddbh3_get_area(h3string, 'km^2'))
#'
#' ## Vectorized mode
#' ddbh3_get_area("8a1fb46622dffff")
ddbh3_get_area <- function(
    x,
    h3 = "h3string",
    unit = "m^2",
    new_column = "h3area",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  assert_unit(unit, c("m^2", "km^2", "rads^2"))

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_area({quote_ident(h3)}, '{unit}')")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    mode = mode,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = glue::glue("h3_cell_area(x, '{unit}')")
  )

}




#' Get the great circle distance between two points
#'
#' Get the great circle (haversine) distance between two points given by
#' their longitude and latitude
#'
#' @template x
#' @param lon_start,lat_start The names of the columns in `x` containing the
#'   longitude and latitude of the start points
#' @param lon_end,lat_end The names of the columns in `x` containing the
#'   longitude and latitude of the end points
#' @param unit Character. Unit of the distance. One of `"m"` (default), `"km"`
#'   or `"rads"`.
#' @param new_column Name of the new column to create on the input data.
#'   Defaults to `"distance"`.
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
#'
#' @export
#'
#' @examples
#' ## Load needed packages
#' library(duckh3)
#' library(dplyr)
#'
#' ## Setup the default connection with h3 and spatial extensions
#' ## This is a mandatory step to use duckh3 functions
#' ddbh3_default_conn(threads = 1)
#'
#' ## Two pairs of points
#' pairs_tbl <- data.frame(
#'   lon1 = c(-3.70, -8.54),
#'   lat1 = c(40.42, 42.88),
#'   lon2 = c(2.17, -8.41),
#'   lat2 = c(41.39, 43.36)
#' )
#'
#' ## Distance in kilometers
#' ddbh3_great_circle_distance(
#'   pairs_tbl,
#'   lon_start = "lon1",
#'   lat_start = "lat1",
#'   lon_end = "lon2",
#'   lat_end = "lat2",
#'   unit = "km"
#' )
#'
#' ## Inside mutate
#' pairs_tbl |>
#'   ddbh3_great_circle_distance("lon1", "lat1", "lon2", "lat2") |>
#'   mutate(dist_km = ddbh3_great_circle_distance(lon1, lat1, lon2, lat2, 'km'))
ddbh3_great_circle_distance <- function(
    x,
    lon_start,
    lat_start,
    lon_end,
    lat_end,
    unit = "m",
    new_column = "distance",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(lon_start, "lon_start")
  duckspatial:::assert_character_scalar(lat_start, "lat_start")
  duckspatial:::assert_character_scalar(lon_end, "lon_end")
  duckspatial:::assert_character_scalar(lat_end, "lat_end")
  assert_unit(unit, c("m", "km", "rads"))

  # 1. Build parameters string
  built_fun <- glue::glue(
    "h3_great_circle_distance(",
    "{quote_ident(lat_start)}, {quote_ident(lon_start)}, ",
    "{quote_ident(lat_end)}, {quote_ident(lon_end)}, '{unit}')"
  )

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    mode = mode,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  )

}




#' Get the average area and edge length of H3 hexagons
#'
#' Get the average area or the average edge length of H3 hexagons at one or
#' more resolutions
#'
#' @param resolution A vector of integers between 0 and 15 with the H3
#'   resolutions
#' @param unit Character. Unit of the result. For
#'   `ddbh3_get_hexagon_area_avg()`, one of `"m^2"` (default) or `"km^2"`. For
#'   `ddbh3_get_hexagon_edge_length_avg()`, one of `"m"` (default) or `"km"`.
#' @template conn_null
#'
#' @details
#' These functions do not take H3 cells as input; they return a constant per
#' resolution. To get the exact area of a cell or the length of a directed
#' edge, use [ddbh3_get_area()] or [ddbh3_get_edge_length()].
#'
#' They also work inside `dplyr::mutate()` with a column of resolutions.
#'
#' @returns A numeric vector with one value per element of `resolution`
#'
#' @name ddbh3_get_hexagon_avg
#' @aliases ddbh3_get_hexagon_area_avg ddbh3_get_hexagon_edge_length_avg
#'
#' @examples
#' ## Load needed packages
#' library(duckh3)
#' library(dplyr)
#'
#' ## Setup the default connection with h3 and spatial extensions
#' ## This is a mandatory step to use duckh3 functions
#' ddbh3_default_conn(threads = 1)
#'
#' ## Average hexagon area at resolution 8, in km2
#' ddbh3_get_hexagon_area_avg(8, unit = "km^2")
#'
#' ## Average edge length at all resolutions
#' ddbh3_get_hexagon_edge_length_avg(0:15)
#'
#' ## Inside mutate
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' ) |>
#'   ddbh3_lonlat_to_h3(resolution = 8)
#'
#' points_tbl |>
#'   mutate(
#'     area = ddbh3_get_area(h3string),
#'     area_avg = ddbh3_get_hexagon_area_avg(ddbh3_get_resolution(h3string))
#'   )
NULL




#' @rdname ddbh3_get_hexagon_avg
#' @export
ddbh3_get_hexagon_area_avg <- function(resolution = 8, unit = "m^2", conn = NULL) {

  # 0. Handle function-specific errors
  assert_unit(unit, c("m^2", "km^2"))

  # 1. Query the extension
  get_resolution_constant(resolution, "h3_get_hexagon_area_avg", unit, conn)

}




#' @rdname ddbh3_get_hexagon_avg
#' @export
ddbh3_get_hexagon_edge_length_avg <- function(resolution = 8, unit = "m", conn = NULL) {

  # 0. Handle function-specific errors
  assert_unit(unit, c("m", "km"))

  # 1. Query the extension
  get_resolution_constant(resolution, "h3_get_hexagon_edge_length_avg", unit, conn)

}
