#' Get the resolution of H3 cell indexes
#'
#' Get the resolution of H3 cell indexes stored as strings or unsigned 64-bit
#' integers (`UBIGINT`) from an existing column.
#'
#' @template x
#' @template h3
#' @template conn_null
#' @template name
#' @template new_column
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
#' @export
#'
#' @examples
#' \dontrun{
#' ## TODO
#' }
ddbh3_get_resolution <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3resolution",
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
    fun = built_fun
  ) 

}
