#' Check properties of H3 cell indexes
#'
#' Check properties of H3 cell indexes stored as strings or unsigned 64-bit
#' integers
#'
#' @template x
#' @template h3
#' @template h3vertex
#' @template new_column
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The functions check different properties of H3 cell indexes, all
#' returning a logical column:
#' * `ddbh3_is_pentagon()`: returns `TRUE` if the H3 cell is one of the 12
#'   pentagonal cells that exist at each H3 resolution
#' * `ddbh3_is_h3()`: returns `TRUE` if the H3 cell index is a valid H3 cell
#' * `ddbh3_is_res_class_iii()`: returns `TRUE` if the H3 cell belongs to a
#'   Class III resolution (odd resolutions: 1, 3, 5, 7, 9, 11, 13, 15)
#' * `ddbh3_is_vertex()`: returns `TRUE` if the index is a valid H3 vertex
#'
#' @template returns_tbl
#'
#' @name ddbh3_is
#' @aliases ddbh3_is_pentagon ddbh3_is_valid ddbh3_is_res_class_iii
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
#' ## IS VALID H3 -------------
#' 
#' ## Check if h3 indexes are valid
#' ddbh3_is_h3(points_tbl)
#' 
#' ## Check in mutate
#' points_tbl |>
#'   mutate(valid = ddbh3_is_h3(h3string))
#' 
#' ## IS PENTAGON -------------
#' 
#' ## Check if h3 indexes are pentagons
#' ddbh3_is_pentagon(points_tbl)
#' 
#' ## Check in mutate
#' points_tbl |>
#'   mutate(is_pent = ddbh3_is_pentagon(h3string))
#' 
#' ## IS CLASS III ------------
#' 
#' ## Check if h3 indexes belong to a Class III resolution
#' ddbh3_is_res_class_iii(points_tbl)
#' 
#' ## Check across multiple resolutions
#' ddbh3_lonlat_to_h3(points_tbl, resolution = 7) |>
#'   ddbh3_is_res_class_iii()
#' 
#' ## IS VERTEX ---------------
#' 
#' ## Get vertexes first
#' vertex_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 1)
#' 
#' ## Check if indexes are valid vertexes
#' ddbh3_is_vertex(vertex_tbl, h3 = "h3vertex")
#' 
#' ## Check in mutate (mix of h3 cells and vertexes)
#' vertex_tbl |>
#'   mutate(
#'     cell_valid  = ddbh3_is_h3(h3string),
#'     vertex_valid = ddbh3_is_vertex(h3vertex)
#'   )
NULL




#' @rdname ddbh3_is
#' @export
ddbh3_is_pentagon <- function(
    x,
    h3 = "h3string",
    new_column = "ispentagon",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_is_pentagon({h3})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_is_pentagon(x)"
  ) 

}




#' @rdname ddbh3_is
#' @export
ddbh3_is_h3 <- function(
    x,
    h3 = "h3string",
    new_column = "ish3",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_is_valid_cell({h3})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_is_valid_cell(x)"
  ) 

}





#' @rdname ddbh3_is
#' @export
ddbh3_is_res_class_iii <- function(
    x,
    h3 = "h3string",
    new_column = "isclassiii",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_is_res_class_iii({h3})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_is_res_class_iii(x)"
  ) 

}




#' @rdname ddbh3_is
#' @export
ddbh3_is_vertex <- function(
    x,
    h3vertex = "h3vertex",
    new_column = "isvertex",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3vertex, "h3vertex")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_is_valid_vertex({h3vertex})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_is_valid_vertex(x)"
  ) 

}
