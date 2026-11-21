#' Work with H3 directed edges
#'
#' Create H3 directed edges from H3 cells, and convert H3 directed edges to
#' cells, lengths and spatial lines. A directed edge goes from an origin cell
#' to one of its neighbors (the destination cell)
#'
#' @template x
#' @template h3
#' @template h3start
#' @template h3end
#' @template h3edge
#' @param unit Character. Unit of the edge length. One of `"m"` (default),
#'   `"km"` or `"rads"`. Only used in `ddbh3_get_edge_length()`.
#' @template new_column
#' @template nested
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @details
#' The functions cover the full directed edge workflow:
#' * `ddbh3_h3_to_edge()` returns the directed edge going from the cell in
#'   `h3start` to the cell in `h3end`. It returns `NA` when the cells are not
#'   neighbors
#' * `ddbh3_h3_to_edges()` returns all directed edges going out of an H3
#'   cell (6 for hexagons, 5 for pentagons) — either nested (one row per cell)
#'   or unnested (one row per edge) depending on `nested`
#' * `ddbh3_edge_to_origin()` returns the origin cell of a directed edge
#' * `ddbh3_edge_to_destination()` returns the destination cell of a
#'   directed edge
#' * `ddbh3_edge_to_h3()` returns both the origin and the destination cells
#'   of a directed edge — either nested (one row per edge) or unnested (one
#'   row per cell) depending on `nested`
#' * `ddbh3_reverse_edge()` returns the directed edge going in the opposite
#'   direction (from destination to origin)
#' * `ddbh3_get_edge_length()` returns the length of a directed edge in `unit`
#' * `ddbh3_edge_to_spatial()` converts directed edges to `LINESTRING`
#'   geometries (`EPSG:4326`) shared by the origin and destination cells
#'
#' Directed edges are returned in the same format as the input cells: strings
#' for H3 strings and `UBIGINT` for H3 unsigned 64-bit integers.
#'
#' @template returns_tbl
#'
#' @name ddbh3_edge
#' @aliases ddbh3_h3_to_edge ddbh3_h3_to_edges ddbh3_edge_to_origin ddbh3_edge_to_destination ddbh3_edge_to_h3 ddbh3_reverse_edge ddbh3_get_edge_length ddbh3_edge_to_spatial
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
#' ## CELLS TO EDGES ---------
#'
#' ## All edges going out of each cell (one row per edge)
#' edges_tbl <- ddbh3_h3_to_edges(points_tbl)
#'
#' ## All edges going out of each cell (one row per cell)
#' ddbh3_h3_to_edges(points_tbl, nested = TRUE)
#'
#' ## Edge between two neighboring cells
#' pair_tbl <- data.frame(
#'   h3start = "8a1fb46622dffff",
#'   h3end   = "8a1fb46622d7fff"
#' )
#' ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = "h3end")
#'
#' ## EDGES TO CELLS ---------
#'
#' ## Origin and destination cells
#' edges_tbl |>
#'   ddbh3_edge_to_origin() |>
#'   ddbh3_edge_to_destination()
#'
#' ## Both cells in a list column
#' ddbh3_edge_to_h3(edges_tbl, nested = TRUE)
#'
#' ## Reverse the direction of the edges
#' ddbh3_reverse_edge(edges_tbl)
#'
#' ## EDGE PROPERTIES --------
#'
#' ## Length of the edges in kilometers
#' ddbh3_get_edge_length(edges_tbl, unit = "km")
#'
#' ## Inside mutate
#' edges_tbl |>
#'   mutate(
#'     origin = ddbh3_edge_to_origin(h3edge),
#'     length = ddbh3_get_edge_length(h3edge, 'm')
#'   )
#'
#' ## EDGES TO SPATIAL -------
#'
#' ## Convert edges to lines
#' ddbh3_edge_to_spatial(edges_tbl)
NULL




#' @rdname ddbh3_edge
#' @export
ddbh3_h3_to_edge <- function(
    x,
    h3start = "h3string",
    h3end,
    new_column = "h3edge",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3start, "h3start")
  duckspatial:::assert_character_scalar(h3end, "h3end")

  # 1. Build parameters string
  built_fun <- glue::glue(
    "h3_cells_to_directed_edge({quote_ident(h3start)}, {quote_ident(h3end)})"
  )

  # 2. Pass to template
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




#' @rdname ddbh3_edge
#' @export
ddbh3_h3_to_edges <- function(
    x,
    h3 = "h3string",
    new_column = "h3edge",
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

  # 1. Build parameters string
  built_fun <- glue::glue("h3_origin_to_directed_edges({quote_ident(h3)})")
  if (!isTRUE(nested)) built_fun <- glue::glue("UNNEST({built_fun})")

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
    base_fun = "h3_origin_to_directed_edges(x)"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_edge_to_origin <- function(
    x,
    h3edge = "h3edge",
    new_column = "h3origin",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_get_directed_edge_origin({quote_ident(h3edge)})")

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
    base_fun = "h3_get_directed_edge_origin(x)",
    validate = "h3_is_valid_directed_edge"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_edge_to_destination <- function(
    x,
    h3edge = "h3edge",
    new_column = "h3destination",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_get_directed_edge_destination({quote_ident(h3edge)})")

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
    base_fun = "h3_get_directed_edge_destination(x)",
    validate = "h3_is_valid_directed_edge"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_edge_to_h3 <- function(
    x,
    h3edge = "h3edge",
    new_column = "h3cells",
    nested = FALSE,
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")
  duckspatial:::assert_logic(nested, "nested")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_directed_edge_to_cells({quote_ident(h3edge)})")
  if (!isTRUE(nested)) built_fun <- glue::glue("UNNEST({built_fun})")

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
    base_fun = "h3_directed_edge_to_cells(x)",
    validate = "h3_is_valid_directed_edge"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_reverse_edge <- function(
    x,
    h3edge = "h3edge",
    new_column = "h3edge_reversed",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_reverse_directed_edge({quote_ident(h3edge)})")

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
    base_fun = "h3_reverse_directed_edge(x)",
    validate = "h3_is_valid_directed_edge"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_get_edge_length <- function(
    x,
    h3edge = "h3edge",
    unit = "m",
    new_column = "edge_length",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")
  duckspatial:::assert_character_scalar(unit, "unit")
  if (!unit %in% c("m", "km", "rads")) {
    cli::cli_abort(
      "The {.arg unit} is not valid. Valid options: {.val {c('m', 'km', 'rads')}}"
    )
  }

  # 1. Build parameters string
  built_fun <- glue::glue("h3_edge_length({quote_ident(h3edge)}, '{unit}')")

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
    base_fun = glue::glue("h3_edge_length(x, '{unit}')"),
    validate = "h3_is_valid_directed_edge"
  )

}




#' @rdname ddbh3_edge
#' @export
ddbh3_edge_to_spatial <- function(
    x,
    h3edge = "h3edge",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3edge, "h3edge")
  if (check_nested_column(x, h3edge)) {
    cli::cli_abort(c(
      "The column {.val {h3edge}} is nested.",
      "i" = "Use {.code nested = FALSE} when creating the edges."
    ))
  }

  # 1. Build parameters string
  built_fun <- build_edge_line(quote_ident(h3edge))

  # 2. Pass to template
  template_h3_to_spatial(
    x = x,
    conn = conn,
    name = name,
    mode = mode,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = build_edge_line("x"),
    validate = "h3_is_valid_directed_edge"
  )

}
