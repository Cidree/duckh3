#' Check properties of H3 cell indexes
#'
#' Check properties of H3 cell indexes stored as strings or unsigned 64-bit
#' integers
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
#' The three functions check different properties of H3 cell indexes, all
#' returning a logical column:
#' * `ddbh3_is_pentagon()` returns `TRUE` if the H3 cell is one of the 12
#'   pentagonal cells that exist at each H3 resolution
#' * `ddbh3_is_valid()` returns `TRUE` if the H3 cell index is a valid H3 cell
#' * `ddbh3_is_res_class_iii()` returns `TRUE` if the H3 cell belongs to a
#'   Class III resolution (odd resolutions: 1, 3, 5, 7, 9, 11, 13, 15)
#'
#' @template returns_tbl
#'
#' @name ddbh3_is
#' @aliases ddbh3_is_pentagon ddbh3_is_valid ddbh3_is_res_class_iii
#'
#' @examples
#' \dontrun{
#' ## TODO
#' }
NULL




#' @rdname ddbh3_is
#' @export
ddbh3_is_pentagon <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "ispentagon",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")


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
    fun = built_fun
  ) 

}




#' @rdname ddbh3_is
#' @export
ddbh3_is_valid <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "isvalid",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")


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
    fun = built_fun
  ) 

}





#' @rdname ddbh3_is
#' @export
ddbh3_is_res_class_iii <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "isclassiii",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")


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
    fun = built_fun
  ) 

}
