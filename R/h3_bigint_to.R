#' Convert H3 bigint indexes to other representations
#'
#' Convert H3 cell indexes stored as unsigned 64-bit integers (`UBIGINT`) into
#' other formats (e.g. H3 strings)
#'
#' @template x
#' @template h3bigint
#' @template conn_null
#' @template name
#' @template new_column
#' @template overwrite
#' @template quiet
#'
#' @details
#' The four functions differ only in the output format:
#' * `ddbh3_bigint_to_strings()` converts H3 indexes to strings (e.g. `"8928308280fffff"`)
#' * `ddbh3_bigint_to_spatial()` converts H3 indexes to spatial hexagon polygons
#' * `ddbh3_bigint_to_lon()` extracts the longitude of the H3 cell centroid
#' * `ddbh3_bigint_to_lat()` extracts the latitude of the H3 cell centroid
#'
#' @template desc_formats
#'
#' @template returns_tbl
#'
#' @name ddbh3_bigint_to
#' @rdname ddbh3_bigint_to
#' @aliases ddbh3_bigint_to_strings ddbh3_bigint_to_spatial ddbh3_bigint_to_lon ddbh3_bigint_to_lat
#'
#' @examples
#' \dontrun{
#' ## TODO
#' }
NULL



#' @rdname ddbh3_bigint_to
#' @export
ddbh3_bigint_to_strings <- function(
    x,
    h3bigint = "h3bigint",
    conn = NULL,
    name = NULL,
    new_column = "h3string",
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3bigint, "h3bigint")
  duckspatial:::assert_character_scalar(new_column, "new_column")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_h3_to_string({h3bigint})")

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




#' @rdname ddbh3_bigint_to
#' @export
ddbh3_bigint_to_lon <- function(
    x,
    h3bigint = "h3bigint",
    conn = NULL,
    name = NULL,
    new_column = "lon",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3bigint, "h3bigint")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("
    h3_cell_to_lng(
      h3_h3_to_string({h3bigint})
    )
  ")


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





#' @rdname ddbh3_bigint_to
#' @export
ddbh3_bigint_to_lat <- function(
    x,
    h3bigint = "h3bigint",
    conn = NULL,
    name = NULL,
    new_column = "lat",
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3bigint, "h3bigint")
  duckspatial:::assert_character_scalar(new_column, "new_column")


  # 1. Build parameters string
  built_fun <- glue::glue("
    h3_cell_to_lat(
      h3_h3_to_string({h3bigint})
    )
  ")

  
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




#' @rdname ddbh3_bigint_to
#' @export
ddbh3_bigint_to_spatial <- function(
    x,
    h3bigint = "h3bigint",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {


  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3bigint, "h3bigint")

  # 1. Build parameters string
  built_fun <- glue::glue("
    ST_GeomFromWKB(
      h3_cell_to_boundary_wkb(
        h3_h3_to_string({h3bigint})
      )
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
