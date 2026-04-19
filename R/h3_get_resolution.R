#' Get the resolution of H3 cell indexes
#'
#' Get the resolution of H3 cell indexes stored as strings or unsigned 64-bit
#' integers (`UBIGINT`) from an existing column.
#'
#' @template x
#' @template h3
#' @template new_column
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
#' @export
#'
#' @examples
#' ## Load needed packages
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
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 10)
#' 
#' ## Convert to duckspatial_df
#' points_ddbs <- ddbs_as_points(points_tbl)
#' 
#' ## Get resolution of the h3 strings
#' ddbh3_get_resolution(points_tbl)
#' ddbh3_get_resolution(points_ddbs, new_column = "res")
#' 
#' ## Add using mutate
#' points_tbl |> 
#'   mutate(res = ddbh3_get_resolution(h3string))
ddbh3_get_resolution <- function(
    x,
    h3 = "h3string",
    new_column = "h3resolution",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_get_resolution({h3})")


  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_get_resolution(x)"
  ) 

}
