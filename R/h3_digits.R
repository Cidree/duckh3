#' Build H3 cells from a base cell and digits
#'
#' Build H3 cell indexes from a base cell number and a set of indexing digits
#'
#' @template x
#' @param base_cell The name of a column in `x` containing the base cell
#'   numbers (between 0 and 121)
#' @param digits The name of a list column in `x` containing the digits of the
#'   cells (integers between 0 and 6, one per resolution)
#' @param new_column Name of the new column to create on the input data.
#'   Defaults to `"h3string"`. If the input already has a column with this
#'   name, it is replaced by the result
#' @param h3_format Character. The format of the H3 cell index: `"string"`
#'   (default) or `"bigint"`
#' @template conn_null
#' @template name
#' @template mode
#' @template overwrite
#' @template quiet
#'
#' @details
#' An H3 cell index is made of a base cell (one of the 122 cells of resolution
#' 0, see [ddbh3_get_base_cell_number()]) and one digit (between 0 and 6) per
#' resolution, from resolution 1 to the resolution of the cell. Each digit is
#' the position of the cell among the 7 children of its parent (pentagons have
#' no digit 1 child).
#'
#' The resolution of the built cell is the number of digits, so an empty list
#' returns the base cell itself (resolution 0). The function returns `NA` when
#' the base cell or any digit is not valid.
#'
#' It also works inside `dplyr::mutate()`, where it always returns H3 strings.
#'
#' @template returns_tbl
#'
#' @seealso [ddbh3_get_base_cell_number()], [ddbh3_get_child_pos()]
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
#' ## Base cells and digits (the first row is the cell 88283470a1fffff)
#' digits_df <- data.frame(base_cell = c(20, 20, 0))
#' digits_df$digits <- list(c(0, 6, 4, 3, 4, 1, 2, 0), c(0, 6, 4), numeric(0))
#'
#' ## Build the cells
#' ddbh3_digits_to_h3(digits_df)
#'
#' ## As UBIGINT
#' ddbh3_digits_to_h3(digits_df, h3_format = "bigint")
#'
#' ## Inside mutate
#' ddbh3_digits_to_h3(digits_df, new_column = "h3cell") |>
#'   mutate(
#'     h3string = ddbh3_digits_to_h3(base_cell, digits),
#'     resolution = ddbh3_get_resolution(h3string)
#'   )
ddbh3_digits_to_h3 <- function(
    x,
    base_cell = "base_cell",
    digits = "digits",
    new_column = "h3string",
    h3_format = "string",
    conn = NULL,
    name = NULL,
    mode = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(base_cell, "base_cell")
  duckspatial:::assert_character_scalar(digits, "digits")
  duckspatial:::assert_character_scalar(h3_format, "h3_format")

  # 1. Build parameters string
  args <- glue::glue("{quote_ident(base_cell)}::INTEGER, {quote_ident(digits)}::INTEGER[]")
  built_fun <- switch(
    h3_format,
    "string" = glue::glue("h3_construct_cell_string({args})"),
    "bigint" = glue::glue("h3_construct_cell({args})"),
    cli::cli_abort("The {.arg h3_format} is not valid. Valid options: {.val {c('string', 'bigint')}}")
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
