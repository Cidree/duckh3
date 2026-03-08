#' Get parent and children H3 cells
#'
#' Get the parent or children H3 cells of H3 cell indexes stored as strings or
#' unsigned 64-bit integers (`UBIGINT`) at a specified resolution:
#' `ddbh3_get_parent()`, `ddbh3_get_center_child()`, `ddbh3_get_children()`,
#' and `ddbh3_get_n_children()`.
#'
#'
#' @template x
#' @template h3
#' @template resolution
#' @template conn_null
#' @template name
#' @template new_column
#' @template nested
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The four functions differ in the type of related cell they retrieve:
#' * `ddbh3_get_parent()` returns the parent cell at a coarser resolution
#' * `ddbh3_get_center_child()` returns the center child cell at a finer resolution
#' * `ddbh3_get_children()` returns all children cells at a finer resolution
#' * `ddbh3_get_n_children()` returns the number of children cells at a finer
#'   resolution, without computing them
#'
#' @template returns_tbl
#'
#' @name ddbh3_get_hierarchy
#' @aliases ddbh3_get_parent ddbh3_get_center_child ddbh3_get_children ddbh3_get_n_children
#'
#' @examples
#' \dontrun{
#' ## Load needed packages
#' library(duckh3)
#' library(dplyr)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add h3 strings
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)
#' 
#' ## GET PARENTS ----------
#' 
#' ## Get resolution-7 parent
#' points_parent_tbl <- ddbh3_get_parent(points_tbl, resolution = 7)
#' 
#' ## Check the resolution
#' ddbh3_get_resolution(
#'   points_parent_tbl,
#'   h3 = "h3parent"
#' )
#' 
#' ## Add with mutate
#' points_tbl |> 
#'   mutate(parent4 = ddbh3_get_parent(h3string, 4))
#' 
#' ## GET CHILDREN ----------
#' 
#' ## Get level 9 children
#' children_9_tbl <- ddbh3_get_children(points_tbl, resolution = 9)
#' 
#' ## Get level 9 children in a nested list
#' children_9_nested_tbl <- ddbh3_get_children(points_tbl, resolution = 9, nested = TRUE)
#' 
#' ## Add with mutate (nested)
#' points_tbl |> 
#'   mutate(children9 = ddbh3_get_children(h3string, 9))
#' 
#' ## Add with mutate (unnested)
#' points_tbl |> 
#'   mutate(children9 = ddbh3_get_children(h3string, 9)) |> 
#'   mutate(children9 = unnest(children9))
#' 
#' ## GET CENTER CHILD ------
#' 
#' ## Get the center child of res 10 (1 child per row)
#' center_child_10_tbl <- ddbh3_get_center_child(points_tbl, resolution = 10)
#' 
#' ## Add with mutate
#' points_tbl |> 
#'   mutate(center = ddbh3_get_center_child(h3string, 9))
#' 
#' ## NUMBER OF CHILDREN -----
#' 
#' ## How many children of level 10 does each level 8 have?
#' n_children_tbl <- ddbh3_get_n_children(points_tbl, resolution = 10)
#' 
#' ## Add with mutate
#' points_tbl |> 
#'   mutate(n_children = ddbh3_get_n_children(h3string, 15))
#' 
#' }
NULL




#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_parent <- function(
    x,
    h3 = "h3string",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3parent",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
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





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_children <- function(
    x,
    h3 = "h3string",
    resolution = 8,
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





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_n_children <- function(
    x,
    h3 = "h3string",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3n_children",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
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





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_center_child <- function(
    x,
    h3 = "h3string",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3center_child",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_center_child({h3}, {resolution})")

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






#' Get the icosahedron faces of H3 cell indexes
#'
#' Get the icosahedron faces intersected by H3 cell indexes stored as strings
#' or unsigned 64-bit integers (`UBIGINT`). Each H3 cell maps onto one or more
#' of the 20 faces of the underlying icosahedron used to construct the H3 grid.
#'
#' @template x
#' @template h3
#' @template conn_null
#' @template name
#' @template new_column
#' @template nested
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
#' library(dplyr)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add H3 string column
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get faces (unnested)
#' faces_tbl <- ddbh3_get_icosahedron_faces(points_tbl)
#' 
#' ## Get faces (nested)
#' faces_nested_tbl <- ddbh3_get_icosahedron_faces(points_tbl, nested = TRUE)
#' 
#' ## Add using mutate (nested)
#' points_tbl |> 
#'   mutate(faces = ddbh3_get_icosahedron_faces(h3string))
#' 
#' ## Add using mutate (unnested)
#' points_tbl |> 
#'   mutate(faces = ddbh3_get_icosahedron_faces(h3string)) |> 
#'   mutate(faces_unnested = unnest(faces))
#' }
ddbh3_get_icosahedron_faces <- function(
    x,
    h3 = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3faces",
    nested = FALSE,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")

  # 1. Build parameters string  
  if (isTRUE(nested)) {
    built_fun <- glue::glue("h3_get_icosahedron_faces({h3})")
  } else {
    built_fun <- glue::glue("UNNEST(h3_get_icosahedron_faces({h3}))")
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





#' Get the position of an H3 cell within its parent
#'
#' Get the position of H3 cell indexes stored as strings or unsigned 64-bit
#' integers (`UBIGINT`) within their parent cell at a specified resolution.
#' The position is a zero-based index among all children of the parent cell.
#'
#' @template x
#' @template h3
#' @template resolution
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
#' library(dplyr)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Add H3 string column
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get position relative to resolution 4
#' ddbh3_get_child_pos(points_tbl, resolution = 4)
#' 
#' ## Add using mutate
#' points_tbl |> 
#'   mutate(child_pos = ddbh3_get_child_pos(h3string, 4))
#' }
ddbh3_get_child_pos <- function(
    x,
    h3 = "h3string",
    resolution = 8,
    conn = NULL,
    name = NULL,
    new_column = "h3child_pos",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_child_pos({h3}, {resolution})")


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



