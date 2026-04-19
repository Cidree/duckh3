#' Convert longitude and latitude to H3 cell representations
#'
#' Convert geographic coordinates (longitude and latitude) into H3 cell
#' representations at a specified resolution, with different output formats
#'
#' @template x
#' @template lon
#' @template lat
#' @template resolution
#' @template new_column
#' @param h3_format Character. The format of the H3 cell index: `string` or
#' `bigint`
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The three functions differ only in the output format of the H3 cell index:
#' * `ddbh3_lonlat_to_h3()` returns H3 cell indexes as strings (e.g. `"8928308280fffff"`) 
#' or as unsigned 64-bit integers (`UBIGINT`)
#' * `ddbh3_lonlat_to_spatial()` returns H3 cells as spatial hexagon polygons
#'
#' @template desc_formats
#' 
#' @template returns_tbl
#'
#' @name ddbh3_lonlat_to
#' @rdname ddbh3_lonlat_to
#' @aliases ddbh3_lonlat_to_h3 ddbh3_lonlat_to_spatial
#'
#' @examples
#' ## Load needed packages
#' library(duckdb)
#' library(duckh3)
#' library(duckspatial)
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
#' ## Create a connection with spatial and h3 extensions
#' conn <- ddbh3_create_conn(threads = 1)
#' 
#' ## TO H3 ------------
#' 
#' ## Add h3 strings as a new column (res 5)
#' points_strings_5_tbl <- ddbh3_lonlat_to_h3(
#'   points_tbl,
#'   resolution = 5
#' )
#' 
#' ## Add h3 UBIGINT as a new column (res 8 by default)
#' points_bigint_8_tbl <- ddbh3_lonlat_to_h3(
#'   points_tbl,
#'   new_column = "h3bigint",
#'   h3_format  = "bigint"
#' )
#' 
#' ## If column names are different from lon/lat:
#' points_renamed <- rename(points_tbl, long = lon, lati = lat)
#' 
#' ddbh3_lonlat_to_h3(
#'   points_renamed,
#'   lon = "long",
#'   lat = "lati",
#'   resolution = 10
#' )
#' 
#' 
#' ## Create a new table in the connection
#' ddbh3_lonlat_to_h3(
#'   points_tbl,
#'   conn = conn,
#'   name = "points_strings_8"
#' )
#' 
#' ## Open the created table lazily
#' points_lazy <- dplyr::tbl(conn, "points_strings_8")
#' 
#' ## Read it in memory
#' points_eager <- dbReadTable(conn, "points_strings_8")
#' 
#' 
#' ## TO SPATIAL -----------
#' 
#' ## Add h3 strings as a new column (res 5)
#' points_5_ddbs <- ddbh3_lonlat_to_spatial(
#'   points_tbl,
#'   resolution = 5
#' )
#' 
#' ## Create a new table in the connection
#' ddbh3_lonlat_to_spatial(
#'   points_tbl,
#'   conn = conn,
#'   name = "points_strings_spatial"
#' )
#' 
#' ## Open the created table lazily
#' as_duckspatial_df("points_strings_spatial", conn)
#' 
#' ## Read it in memory as an sf object
#' ddbs_read_table(conn, "points_strings_spatial")
NULL





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
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

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
ddbh3_lonlat_to_h3 <- function(
    x,
    lon = "lon",
    lat = "lat",
    resolution = 8,
    new_column = "h3string",
    h3_format = "string",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(lon, "lon")
  duckspatial:::assert_character_scalar(lat, "lat")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Build parameters string
  built_fun <- switch(
    h3_format,
    "string" = glue::glue("h3_latlng_to_cell_string({lat}, {lon}, {resolution})"),
    "bigint" = glue::glue("h3_latlng_to_cell({lat}, {lon}, {resolution})"),
    cli::cli_abort("The {.arg h3_format} is not valid. Valid options: {.val {c('string', 'bigint')}}")
  )

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
