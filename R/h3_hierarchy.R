#' Get parent and children H3 cells
#'
#' Get the parent or children H3 cells of H3 cell indexes stored as strings or
#' unsigned 64-bit integers (`UBIGINT`) at a specified resolution:
#' `ddbh3_get_parent()`, `ddbh3_get_center_child()`, `ddbh3_get_children()`,
#' and `ddbh3_get_n_children()`.
#'
#'
#' @template x
#' @template resolution
#' @template h3
#' @template new_column
#' @template conn_null
#' @template name
#' @template mode
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
NULL




#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_parent <- function(
    x,
    resolution = 8,
    h3 = "h3string",
    new_column = "h3parent",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_parent({quote_ident(h3)}, {resolution})")

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
    base_fun = glue::glue("h3_cell_to_parent(x, {resolution})")
  ) 

}





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_children <- function(
    x,
    resolution = 8,
    h3 = "h3string",
    new_column = "h3children",
    conn = NULL,
    name = NULL,
    mode = NULL,
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
    built_fun <- glue::glue("h3_cell_to_children({quote_ident(h3)}, {resolution})")
  } else {
    built_fun <- glue::glue("UNNEST(h3_cell_to_children({quote_ident(h3)}, {resolution}))")
  }

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
    base_fun = glue::glue("h3_cell_to_children(x, {resolution})")
  ) 

}





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_n_children <- function(
    x,
    resolution = 8,
    h3 = "h3string",
    new_column = "h3n_children",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_children_size({quote_ident(h3)}, {resolution})")

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
    base_fun = glue::glue("h3_cell_to_children_size(x, {resolution})")
  ) 

}





#' @rdname ddbh3_get_hierarchy
#' @export
ddbh3_get_center_child <- function(
    x,
    resolution = 8,
    h3 = "h3string",
    new_column = "h3center_child",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_center_child({quote_ident(h3)}, {resolution})")

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
    base_fun = glue::glue("h3_cell_to_center_child(x, {resolution})")
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
#' @template new_column
#' @template conn_null
#' @template name
#' @template mode
#' @template nested
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
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
ddbh3_get_icosahedron_faces <- function(
    x,
    h3 = "h3string",
    new_column = "h3faces",
    conn = NULL,
    name = NULL,
    mode = NULL,
    nested = FALSE,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_logic(nested, "nested")

  # 1. Build parameters string  
  if (isTRUE(nested)) {
    built_fun <- glue::glue("h3_get_icosahedron_faces({quote_ident(h3)})")
  } else {
    built_fun <- glue::glue("UNNEST(h3_get_icosahedron_faces({quote_ident(h3)}))")
  }

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
    base_fun = glue::glue("h3_get_icosahedron_faces(x)")
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
#' @template new_column
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
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
#' ## Add H3 string column
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get position relative to resolution 4
#' ddbh3_get_child_pos(points_tbl, resolution = 4)
ddbh3_get_child_pos <- function(
    x,
    resolution = 8,
    h3 = "h3string",
    new_column = "h3child_pos",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_child_pos({quote_ident(h3)}, {resolution})")


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
    base_fun = glue::glue("h3_cell_to_child_pos(x, {resolution})")
  ) 

}



#' Get an H3 child cell from a parent and child position
#'
#' Get the child H3 cell at a given position within a parent cell at a 
#' specified child resolution.
#'
#' @template x
#' @param child_pos Numeric. Column name containing the child position index.
#' @param parent Character. Column name containing the parent H3 cell index.
#' @template resolution
#' @template new_column
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
#' @export
ddbh3_child_pos_to_cell <- function(
    x,
    child_pos = "h3child_pos",
    parent = "h3string",
    resolution = 8,
    new_column = "h3children",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(child_pos, "child_pos")
  duckspatial:::assert_character_scalar(parent, "parent")
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")


  # 1. Build parameters string
  ## cast doubles (R's default numeric) to BIGINT, but error on fractional
  ## positions instead of silently rounding them
  child_pos_q <- quote_ident(child_pos)
  child_pos_int <- glue::glue(
    "CAST(CASE WHEN {child_pos_q} = TRUNC({child_pos_q}) THEN {child_pos_q} ",
    "ELSE error('child_pos must be a whole number') END AS BIGINT)"
  )
  built_fun <- glue::glue("h3_child_pos_to_cell({child_pos_int}, {quote_ident(parent)}, {resolution})")


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
    base_fun = glue::glue("h3_child_pos_to_cell(x, y, {resolution})")
  ) 

}




#' Get the base cell number of an H3 cell
#'
#' Get the base cell number (ranging from 0 to 121) of H3 cell indexes stored 
#' as strings or unsigned 64-bit integers (`UBIGINT`). Every H3 cell descends 
#' from one of these foundational global base cells.
#'
#' @template x
#' @template h3
#' @template new_column
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @template returns_tbl
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
#' ## Add H3 string column
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' ## Get the base cell number
#' ddbh3_get_base_cell_number(points_tbl)
ddbh3_get_base_cell_number <- function(
    x,
    h3 = "h3string",
    new_column = "base_cell",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_get_base_cell_number({h3})")


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
    base_fun = glue::glue("h3_get_base_cell_number(x)")
  ) 

}



#' Compact and uncompact sets of H3 cells
#'
#' Compact a set of H3 cells into the smallest set of (possibly coarser) cells
#' covering the same area, or uncompact a set of cells to a single resolution
#'
#' @template x
#' @template h3
#' @param by Character vector with the names of the columns used to group the
#'   cells before compacting them (e.g. one compacted set per region). If
#'   `NULL` (default), all the cells of `x` are compacted together.
#' @param resolution A number specifying the resolution of the uncompacted
#'   cells (between 0 and 15). It must be equal to or finer than the
#'   resolution of every input cell.
#' @param new_column Name of the new column to create on the input data.
#'   Defaults to `"h3compact"` for `ddbh3_compact()` and `"h3uncompact"` for
#'   `ddbh3_uncompact()`.
#' @param nested Logical. If `TRUE`, the cells are returned as a nested list
#'   column (one row per group in `ddbh3_compact()`, one row per input row in
#'   `ddbh3_uncompact()`). If `FALSE` (default), the result is unnested so
#'   each cell occupies its own row.
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @details
#' * `ddbh3_compact()` is an aggregation: it replaces every complete set of
#'   children by their parent, recursively. The output only keeps the `by`
#'   columns and the compacted cells, and it is never spatial (use
#'   [ddbh3_h3_to_spatial()] to get the hexagons). Duplicated cells are
#'   removed before compacting. If a group contains invalid cells, its result
#'   is `NULL` (with `nested = TRUE`) or the group is dropped (with
#'   `nested = FALSE`). The `h3` column can also be a list column of cells.
#' * `ddbh3_uncompact()` expands each cell (or each list of cells, if `h3` is
#'   a list column) to all its descendants at `resolution`. Cells already at
#'   `resolution` are kept. It keeps the rest of the columns. If a cell is
#'   finer than `resolution`, the result for that row is `NULL` (with
#'   `nested = TRUE`) or the row is dropped (with `nested = FALSE`).
#'
#' Inside `dplyr`, `ddbh3_compact(h3)` works as an aggregate function in
#' `summarise()`, and `ddbh3_uncompact(h3, resolution)` works in `mutate()` on
#' a list column of cells.
#'
#' @returns For `ddbh3_compact()`, a `tbl_lazy` (or `TRUE` invisibly if `name`
#'   is provided). For `ddbh3_uncompact()`, the same outputs as the rest of
#'   the package:
#'   \describe{
#'     \item{`tbl_lazy`}{If `x` is not spatial. `mode` is ignored in this case.}
#'     \item{`duckspatial_df`}{If `x` is spatial (e.g. an `sf` or `duckspatial_df`
#'       object) and `mode = "duckspatial"` (default).}
#'     \item{`sf`}{If `x` is spatial and `mode = "sf"`.}
#'     \item{`TRUE` (invisibly)}{If `name` is provided, a table is created in the connection
#'       and `TRUE` is returned invisibly.}
#'   }
#'   In vectorized mode (`x` is a vector of cells and `conn = NULL`), both
#'   functions return a vector with the compacted or uncompacted set of cells.
#'
#' @name ddbh3_compact
#' @aliases ddbh3_uncompact
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
#' ## All the children of two cells, plus one extra cell
#' cells_tbl <- data.frame(
#'   region   = c("A", "B", "B"),
#'   h3string = c("87283472bffffff", "872834729ffffff", "88283470a1fffff")
#' ) |>
#'   ddbh3_get_children(resolution = 8, h3 = "h3string", new_column = "h3children")
#'
#' ## COMPACT ------------------
#'
#' ## Compact all the cells together
#' ddbh3_compact(cells_tbl, h3 = "h3children")
#'
#' ## Compact the cells of each region
#' compact_tbl <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region")
#' compact_tbl
#'
#' ## One row per region with a list of cells
#' ddbh3_compact(cells_tbl, h3 = "h3children", by = "region", nested = TRUE)
#'
#' ## Inside summarise
#' cells_tbl |>
#'   summarise(h3compact = ddbh3_compact(h3children), .by = region)
#'
#' ## UNCOMPACT ----------------
#'
#' ## Back to resolution 8
#' ddbh3_uncompact(compact_tbl, h3 = "h3compact", resolution = 8)
#'
#' ## Vectorized mode
#' ddbh3_uncompact("87283472bffffff", resolution = 8) |>
#'   ddbh3_compact()
NULL




#' @rdname ddbh3_compact
#' @export
ddbh3_compact <- function(
    x,
    h3 = "h3string",
    by = NULL,
    new_column = "h3compact",
    nested = FALSE,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_logic(nested, "nested")
  if (!is.null(by) && (!is.character(by) || length(by) == 0 || anyNA(by))) {
    cli::cli_abort("{.arg by} must be a character vector with column names.")
  }

  # 1. Vectorized mode: compact the whole vector
  if (is.null(conn) && (is.character(x) || is.numeric(x))) {
    get_vectorized_result(x, "x")
    res <- get_vectorized_result(
      x, "h3_compact_cells(list_distinct(list(x)))", validate = NULL
    )
    return(res[[1]])
  }

  # 2. Build the aggregation query
  is_nested <- check_nested_column(x, h3, conn)
  cells     <- if (is_nested) {
    glue::glue("list_distinct(flatten(list({quote_ident(h3)})))")
  } else {
    glue::glue("list_distinct(list({quote_ident(h3)}))")
  }
  compact_expr <- glue::glue("h3_compact_cells({cells})")

  by_select <- if (is.null(by)) "" else paste0(paste(quote_ident(by), collapse = ", "), ", ")
  by_group  <- if (is.null(by)) "" else glue::glue("GROUP BY {paste(quote_ident(by), collapse = ', ')}")

  build_query <- function(query_name) {
    agg_query <- glue::glue("
      SELECT {by_select}{compact_expr} AS {quote_ident(new_column)}
      FROM {query_name}
      {by_group}
    ")
    if (isTRUE(nested)) return(agg_query)
    glue::glue("
      SELECT * REPLACE (UNNEST({quote_ident(new_column)}) AS {quote_ident(new_column)})
      FROM ({agg_query})
    ")
  }

  # 3. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    build_query = build_query
  )

}




#' @rdname ddbh3_compact
#' @export
ddbh3_uncompact <- function(
    x,
    h3 = "h3string",
    resolution = 8,
    new_column = "h3uncompact",
    nested = FALSE,
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_logic(nested, "nested")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")

  # 1. Vectorized mode: uncompact the whole vector
  if (is.null(conn) && (is.character(x) || is.numeric(x))) {
    get_vectorized_result(x, "x")
    res <- get_vectorized_result(
      x,
      glue::glue("h3_uncompact_cells(list_distinct(list(x)), {resolution})"),
      validate = NULL
    )
    return(res[[1]])
  }

  # 2. Build parameters string (a single cell is wrapped in a list)
  cells <- if (check_nested_column(x, h3, conn)) {
    quote_ident(h3)
  } else {
    glue::glue("[{quote_ident(h3)}]")
  }
  built_fun <- glue::glue("h3_uncompact_cells({cells}, {resolution})")
  if (!isTRUE(nested)) built_fun <- glue::glue("UNNEST({built_fun})")

  # 3. Pass to template
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
