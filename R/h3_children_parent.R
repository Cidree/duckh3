#' Get the parent H3 cell of H3 indexes
#'
#' Get the parent H3 cell of H3 cell indexes stored as strings or unsigned
#' 64-bit integers (`UBIGINT`) at a specified resolution.
#'
#' @template x
#' @template resolution
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
#' ## Load needed packages
#' library(duckh3)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 10)
#' 
#' ## Get resolution-7 parent
#' points_parent_tbl <- ddbh3_get_parent(points_tbl, 7)
#' 
#' ## Check the resolution
#' ddbh3_get_resolution(
#'   points_parent_tbl,
#'   h3 = "h3parent"
#' )
#' }
ddbh3_get_parent <- function(
    x,
    resolution,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3parent",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_parent({h3}, {resolution})")


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





#' Get the children H3 cells of H3 indexes
#'
#' Get the children H3 cells of H3 cell indexes stored as strings or unsigned
#' 64-bit integers (`UBIGINT`) at a specified resolution.
#'
#' @template x
#' @template resolution
#' @template h3
#' @template conn_null
#' @template name
#' @template new_column
#' @param nested Logical. If `TRUE`, children are returned as a nested list
#'   column (one row per parent cell). If `FALSE` (default), the result is
#'   unnested so each child cell occupies its own row.
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
#' @export
#'
#' @examples
#' \dontrun{
#' ## Load needed packages
#' library(duckh3)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get level 8 children
#' children_8_tbl <- ddbh3_get_children(points_tbl, 8)
#' 
#' ## Get level 8 children in a nested list
#' children_8_nested_tbl <- ddbh3_get_children(points_tbl, 8, nested = TRUE)
#' }
ddbh3_get_children <- function(
    x,
    resolution,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3children",
    nested = FALSE,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_logic(nested, "nested")
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  if (isTRUE(nested)) {
    built_fun <- glue::glue("h3_cell_to_children({h3}, {resolution})")
  } else {
    built_fun <- glue::glue("UNNEST(h3_cell_to_children({h3}, {resolution}))")
  }
  


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





#' Get the number of children of H3 cell indexes
#'
#' Get the number of children of H3 cell indexes stored as strings or unsigned
#' 64-bit integers (`UBIGINT`) at a specified resolution.
#'
#' @template x
#' @template resolution
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
#' ## Load needed packages
#' library(duckh3)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get number of children of resolution 9
#' ddbh3_get_n_children(points_tbl, 9)
#' }
ddbh3_get_n_children <- function(
    x,
    resolution,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3n_children",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_children_size({h3}, {resolution})")


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
