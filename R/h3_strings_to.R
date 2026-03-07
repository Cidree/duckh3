#' Convert H3 string indexes to other representations
#'
#' Convert H3 cell indexes stored as strings into other representations:
#' `ddbh3_strings_to_bigint()`, `ddbh3_strings_to_spatial()`,
#' `ddbh3_strings_to_lon()`, and `ddbh3_strings_to_lat()`.
#'
#' @template x
#' @template h3string
#' @template conn_null
#' @template name
#' @template new_column
#' @template overwrite
#' @template quiet
#'
#' @details
#' The four functions differ only in the output format:
#' * `ddbh3_strings_to_bigint()` converts H3 indexes to unsigned 64-bit integers (`UBIGINT`)
#' * `ddbh3_strings_to_spatial()` converts H3 indexes to spatial hexagon polygons
#' * `ddbh3_strings_to_lon()` extracts the longitude of the H3 cell centroid
#' * `ddbh3_strings_to_lat()` extracts the latitude of the H3 cell centroid
#'
#' @template desc_formats
#'
#' @template returns_tbl
#'
#' @name ddbh3_strings_to
#' @rdname ddbh3_strings_to
#' @aliases ddbh3_strings_to_bigint ddbh3_strings_to_spatial ddbh3_strings_to_lon ddbh3_strings_to_lat
#'
#' @examples
#' \dontrun{
#' ## TODO
#' }
NULL






#' @rdname ddbh3_strings_to
#' @export
ddbh3_strings_to_bigint <- function(
    x,
    h3string = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "h3bigint",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3string, "h3string")
  duckspatial:::assert_character_scalar(new_column, "new_column")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_string_to_h3({h3string})")

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




#' @rdname ddbh3_strings_to
#' @export
ddbh3_strings_to_lon <- function(
    x,
    h3string = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "lon",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3string, "h3string")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_lng({h3string})")


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





#' @rdname ddbh3_strings_to
#' @export
ddbh3_strings_to_lat <- function(
    x,
    h3string = "h3string",
    conn = NULL,
    name = NULL,
    new_column = "lat",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3string, "h3string")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_lat({h3string})")

  
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





#' @rdname ddbh3_strings_to
#' @export
ddbh3_strings_to_spatial <- function(
    x,
    h3string = "h3string",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3string, "h3string")

  # 1. Build parameters string
  built_fun <- glue::glue("
    ST_GeomFromWKB(
      h3_cell_to_boundary_wkb({h3string})
    )"
  )

  # 2. Pass to template
  template_h3_to_spatial(
    x = x,
    conn = conn,
    name = name,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  ) 

}
