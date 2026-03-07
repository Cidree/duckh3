#' Convert longitude and latitude to H3 cell representations
#'
#' Convert geographic coordinates (longitude and latitude) into H3 cell
#' representations at a specified resolution, with different output formats
#'
#' @template x
#' @template lon
#' @template lat
#' @template resolution
#' @template conn_null
#' @template name
#' @template new_column
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The three functions differ only in the output format of the H3 cell index:
#' * `ddbh3_lonlat_to_strings()` returns H3 cell indexes as strings (e.g. `"8928308280fffff"`)
#' * `ddbh3_lonlat_to_bigint()` returns H3 cell indexes as unsigned 64-bit integers (`UBIGINT`)
#' * `ddbh3_lonlat_to_spatial()` returns H3 cells as spatial hexagon polygons
#'
#' @template desc_formats
#' 
#' @template returns_tbl
#'
#' @name ddbh3_lonlat_to
#' @rdname ddbh3_lonlat_to
#' @aliases ddbh3_lonlat_to_strings ddbh3_lonlat_to_bigint ddbh3_lonlat_to_spatial
#'
#' @examples
#' \dontrun{
#' ## TODO
#' }
NULL



#' @rdname ddbh3_lonlat_to
#' @export
ddbh3_lonlat_to_strings <- function(
    x,
    lon = "lon",
    lat = "lat",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3string",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(lon, "lon")
  duckspatial:::assert_character_scalar(lat, "lat")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 18, "resolution")

   # 1. Build parameters string
  built_fun <- glue::glue("h3_latlng_to_cell_string({lat}, {lon}, {resolution})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  ) 

}




#' @rdname ddbh3_lonlat_to
#' @export
ddbh3_lonlat_to_spatial <- function(
    x,
    lon = "lon",
    lat = "lat",
    resolution = 8,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(lon, "lon")
  duckspatial:::assert_character_scalar(lat, "lat")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 18, "resolution")

  # 1. Build parameters string
  built_fun <- glue::glue("
    ST_GeomFromWKB(
      h3_cell_to_boundary_wkb(
        h3_latlng_to_cell_string({lat}, {lon}, {resolution})
      )
    )"
  )

  # 2. Pass to template
  template_h3_to_spatial(
    x = x,
    conn = conn,
    name = name,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  ) 

}




#' @rdname ddbh3_lonlat_to
#' @export
ddbh3_lonlat_to_bigint <- function(
    x,
    lon = "lon",
    lat = "lat",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3bigint",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(lon, "lon")
  duckspatial:::assert_character_scalar(lat, "lat")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 18, "resolution")

   # 1. Build parameters string
  built_fun <- glue::glue("
    h3_string_to_h3(
      h3_latlng_to_cell_string({lat}, {lon}, {resolution})
    )::UBIGINT
  ")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  ) 

}