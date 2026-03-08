#' Convert H3 string or UBIGINT indexes to other representations
#'
#' Convert H3 cell indexes stored as strings or UBIGINT into other 
#' representations (e.g. `lon`, `lat`, `spatial`)
#'
#' @template x
#' @template h3
#' @template conn_null
#' @template name
#' @template new_column
#' @template overwrite
#' @template quiet
#'
#' @details
#' The four functions differ only in the output format:
#' * `ddbh3_h3_to_spatial()` converts H3 indexes to spatial hexagon polygons
#' * `ddbh3_h3_to_lon()` extracts the longitude of the H3 cell centroid
#' * `ddbh3_h3_to_lat()` extracts the latitude of the H3 cell centroid
#' * `ddbh3_strings_to_bigint()` converts H3 indexes to unsigned 64-bit integers (`UBIGINT`)
#' * `ddbh3_bigint_to_strings()` converts H3 indexes to strings (e.g. `"8928308280fffff"`)
#'
#' @template desc_formats
#'
#' @template returns_tbl
#'
#' @name ddbh3_h3_to
#' @rdname ddbh3_h3_to
#' @aliases ddbh3_h3_to_spatial ddbh3_h3_to_lon ddbh3_h3_to_lat ddbh3_strings_to_bigint ddbh3_bigint_to_strings
#'
#' @examples
#' \dontrun{
#' ## Load needed packages
#' library(duckh3)
#' library(duckspatial)
#' library(dplyr)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add H3 string column
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6) |> 
#'   select(-lon, -lat)
#' 
#' ## TO LON/LAT ------------
#' 
#' ## Add longitude and latitude of the H3 string
#' points_coords_tbl <- points_tbl |> 
#'   ddbh3_h3_to_lat() |> 
#'   ddbh3_h3_to_lon()
#' 
#' ## Add lon/lat with other names
#' points_coords_2_tbl <- points_tbl |> 
#'   ddbh3_h3_to_lat(new_column = "latitude") |> 
#'   ddbh3_h3_to_lon(new_column = "longitude")
#' 
#' ## Add using mutate
#' points_tbl |> 
#'   mutate(
#'     lon = ddbh3_h3_to_lon(h3string),
#'     lat = ddbh3_h3_to_lat(h3string)
#'   )
#' 
#' ## TO SPATIAL -----------------
#' 
#' ## Convert h3 strings to spatial polygons
#' points_ddbs <- ddbh3_h3_to_spatial(points_tbl)
#' 
#' ## Collect as sf
#' points_sf <- ddbs_collect(points_ddbs)
#' 
#' ## FROM STRING TO UBIGINT -----
#' 
#' ## Add ubigint, and remove strings
#' points_bigint_tbl <- ddbh3_strings_to_bigint(
#'   points_tbl, 
#'   new_column = "h3_integers"
#' ) |> 
#'   select(-h3string)
#' 
#' ## Add using mutate
#' points_tbl |> 
#'   mutate(h3int = ddbh3_strings_to_bigint(h3string))
#' 
#' ## FROM UBIGINT TO STRING -----
#' 
#' ## Add column with strings
#' points_strings_tbl <- ddbh3_bigint_to_strings(
#'   points_bigint_tbl, 
#'   h3 = "h3_integers"
#' ) 
#' 
#' ## Add using mutate
#' points_bigint_tbl |> 
#'   mutate(h3string = ddbh3_bigint_to_strings(h3_integers))
#' 
#' }
NULL





#' @rdname ddbh3_h3_to
#' @export
ddbh3_h3_to_lon <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "lon",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_lng({h3})")

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





#' @rdname ddbh3_h3_to
#' @export
ddbh3_h3_to_lat <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "lat",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_lat({h3})")

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





#' @rdname ddbh3_h3_to
#' @export
ddbh3_h3_to_spatial <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("
    ST_GeomFromWKB(
      h3_cell_to_boundary_wkb({h3})
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





#' @rdname ddbh3_h3_to
#' @export
ddbh3_strings_to_bigint <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3bigint",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_string_to_h3({h3})")

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



#' @rdname ddbh3_h3_to
#' @export
ddbh3_bigint_to_strings <- function(
    x,
    h3 = "h3bigint",
    conn = NULL,
    name = NULL,
    new_column = "h3string",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_h3_to_string({h3})")

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
