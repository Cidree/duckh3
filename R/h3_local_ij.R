#' Work with H3 local IJ coordinates
#'
#' Convert H3 cells to local IJ coordinates relative to an origin cell, and
#' local IJ coordinates back to H3 cells
#'
#' @template x
#' @param origin The name of a column in `x` containing the H3 cells used as
#'   origin of the local IJ coordinate system
#' @template h3
#' @param i,j The names of the columns in `x` containing the local I and J
#'   coordinates
#' @param new_column Name of the new column(s) to create on the input data. For
#'   `ddbh3_h3_to_local_ij()`, a character vector of length 2 with the names of
#'   the I and J columns (defaults to `c("i", "j")`). For
#'   `ddbh3_local_ij_to_h3()`, the name of the cell column (defaults to
#'   `"h3cell"`). If the input already has a column with any of these names, it
#'   is replaced by the result
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @details
#' Local IJ coordinates are integer coordinates of a cell in a 2D grid
#' anchored at an origin cell. They are useful to work with cells as a regular
#' grid (e.g. offsets between cells or image-like operations):
#' * `ddbh3_h3_to_local_ij()` adds two integer columns with the I and J
#'   coordinates of the cell in `h3` relative to the cell in `origin`
#' * `ddbh3_local_ij_to_h3()` returns the cell at the I and J coordinates
#'   relative to the cell in `origin`. The cell is returned in the same format
#'   as `origin` (string or `UBIGINT`)
#'
#' Local IJ coordinates are only defined near the origin: the origin and the
#' cell must have the same resolution and be close enough to each other (and
#' not cross pentagon distortion). Otherwise, the result is `NA`. The origin
#' is not placed at `(0, 0)`, and the coordinates are only comparable between
#' cells that share the same origin.
#'
#' Both functions work inside `dplyr::mutate()`. There,
#' `ddbh3_h3_to_local_ij(origin, h3)` returns a list column with the `[i, j]`
#' pair; use `ij[[1]]` and `ij[[2]]` to extract each coordinate.
#'
#' @template returns_tbl
#'
#' @name ddbh3_local_ij
#' @aliases ddbh3_h3_to_local_ij ddbh3_local_ij_to_h3
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
#' ## Cells within 2 steps of an origin cell
#' cells_tbl <- data.frame(origin = "88283470a1fffff") |>
#'   ddbh3_grid_disk(k = 2, h3 = "origin", new_column = "h3string")
#'
#' ## CELLS TO LOCAL IJ ------
#'
#' ## Local IJ coordinates relative to the origin
#' ij_tbl <- ddbh3_h3_to_local_ij(cells_tbl, origin = "origin")
#' ij_tbl
#'
#' ## Custom column names
#' ddbh3_h3_to_local_ij(cells_tbl, origin = "origin", new_column = c("col", "row"))
#'
#' ## LOCAL IJ TO CELLS ------
#'
#' ## Back to the original cells
#' ddbh3_local_ij_to_h3(ij_tbl, origin = "origin")
#'
#' ## Shift the cells one step along the I axis
#' ij_tbl |>
#'   mutate(i = i + 1L) |>
#'   ddbh3_local_ij_to_h3(origin = "origin", new_column = "h3shifted")
#'
#' ## Inside mutate (`ij[[1]]` extracts the I coordinate)
#' ij_tbl |>
#'   mutate(
#'     ij = ddbh3_h3_to_local_ij(origin, h3string),
#'     i_mutate = ij[[1]],
#'     h3cell = ddbh3_local_ij_to_h3(origin, i, j)
#'   )
NULL




#' @rdname ddbh3_local_ij
#' @export
ddbh3_h3_to_local_ij <- function(
    x,
    origin,
    h3 = "h3string",
    new_column = c("i", "j"),
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(origin, "origin")
  duckspatial:::assert_character_scalar(h3, "h3")
  if (
    !is.character(new_column) || length(new_column) != 2L || anyNA(new_column) ||
      tolower(new_column[1]) == tolower(new_column[2])
  ) {
    cli::cli_abort("{.arg new_column} must be a character vector with 2 different names.")
  }

  # 1. Build parameters string (one expression per new column)
  ij_fun    <- glue::glue("h3_cell_to_local_ij({quote_ident(origin)}, {quote_ident(h3)})")
  built_fun <- c(glue::glue("{ij_fun}[1]"), glue::glue("{ij_fun}[2]"))

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




#' @rdname ddbh3_local_ij
#' @export
ddbh3_local_ij_to_h3 <- function(
    x,
    origin,
    i = "i",
    j = "j",
    new_column = "h3cell",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(origin, "origin")
  duckspatial:::assert_character_scalar(i, "i")
  duckspatial:::assert_character_scalar(j, "j")

  # 1. Build parameters string
  built_fun <- glue::glue(
    "h3_local_ij_to_cell(",
    "{quote_ident(origin)}, {quote_ident(i)}::INTEGER, {quote_ident(j)}::INTEGER)"
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
