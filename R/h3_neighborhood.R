
#' Get H3 grid neighborhoods (disks, rings, and distances)
#'
#' Functions to generate surrounding H3 neighborhood cells based on step-by-step 
#' grid distances (k-rings and hollow rings).
#'
#' @template x
#' @param k Integer. The grid distance (number of neighbor hops). Defaults to `1`.
#' @template h3
#' @template new_column
#' @template nested
#' @template safe
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#' 
#' @details
#' These functions differ in how they traverse and select neighborhood cells:
#' * __`ddbh3_grid_disk()`__: Returns all H3 cells within a grid distance 
#'     \code{k} from the origin cell (inclusive of all rings from distance 0 up to `k`).
#' * __`dbh3_grid_disk_distances()`__: Similar to grid disk, but leverages the 
#'     underlying distance-aware function variant to extract neighborhood cells.
#' * __`ddbh3_grid_ring()`__: Returns only the exact hollow ring of H3 cells 
#'     located at the specific distance `k` from the origin cell, excluding 
#'     all inner cells.
#'
#' @template returns_tbl
#' @name ddbh3_grid_disk
#' @rdname ddbh3_grid_disk
#' @export
#'
#' @examples
#' library(duckh3)
#' library(dplyr)
#' 
#' ddbh3_default_conn(threads = 1)
#' points_tbl <- read.csv(system.file("extdata/example_pts.csv", package = "duckh3"))
#' points_tbl <- ddbh3_lonlat_to_h3(points_tbl, resolution = 6)
#' 
#' # Get grid disk (k = 1)
#' ddbh3_grid_disk(points_tbl, k = 1)
NULL


#' @rdname ddbh3_grid_disk
#' @export
ddbh3_grid_disk <- function(
    x,
    k = 1,
    h3 = "h3string",
    new_column = "h3neighbors",
    conn = NULL,
    name = NULL,
    nested = FALSE,
    overwrite = FALSE,
    safe = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_logic(nested, "nested")
  duckspatial:::assert_logic(safe, "safe")
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(k, "k")

  # Select safe vs unsafe function variant
  base_fname <- if (isTRUE(safe)) "h3_grid_disk" else "h3_grid_disk_unsafe"

  # 1. Build parameters string
  if (isTRUE(nested)) {
    built_fun <- glue::glue("{base_fname}({h3}, {k})")
  } else {
    built_fun <- glue::glue("UNNEST({base_fname}({h3}, {k}))")
  }

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = glue::glue("{base_fname}(x, {k})")
  ) 

}


#' @rdname ddbh3_grid_disk
#' @export
ddbh3_grid_disk_distances <- function(
    x,
    k = 1,
    h3 = "h3string",
    new_column = "h3neighbors",
    conn = NULL,
    name = NULL,
    nested = FALSE,
    overwrite = FALSE,
    safe = TRUE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_logic(nested, "nested")
  duckspatial:::assert_logic(safe, "safe")
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(k, "k")

  # Select safe vs unsafe function variant
  base_fname <- if (isTRUE(safe)) "h3_grid_disk_distances" else "h3_grid_disk_distances_unsafe"

  # 1. Build parameters string using list indexing [2] to get the cells
  if (isTRUE(nested)) {
    built_fun <- glue::glue("{base_fname}({h3}, {k})[2]")
  } else {
    built_fun <- glue::glue("unnest({base_fname}({h3}, {k})[2])")
  }

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = glue::glue("{base_fname}(x, {k})")
  ) 

}


#' @rdname ddbh3_grid_disk
#' @export
ddbh3_grid_ring <- function(
    x,
    k = 1,
    h3 = "h3string",
    new_column = "h3neighbors",
    conn = NULL,
    name = NULL,
    nested = FALSE,
    overwrite = FALSE,
    safe = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_logic(nested, "nested")
  duckspatial:::assert_logic(safe, "safe")
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(k, "k")

  # Select safe vs unsafe function variant
  base_fname <- if (isTRUE(safe)) "h3_grid_ring" else "h3_grid_ring_unsafe"

  # 1. Build parameters string
  if (isTRUE(nested)) {
    built_fun <- glue::glue("{base_fname}({h3}, {k})")
  } else {
    built_fun <- glue::glue("UNNEST({base_fname}({h3}, {k}))")
  }

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = glue::glue("{base_fname}(x, {k})")
  ) 

}



#' Get the maximum grid disk size for a given distance k
#'
#' Computes the theoretical maximum number of cells contained within a 
#' grid disk of a specified grid distance \code{k}.
#'
#' @param k Integer. The maximum grid distance (k-ring radius).
#' @param conn A DuckDB connection object. If `NULL`, uses or creates the default connection.
#'
#' @return An integer scalar representing the maximum number of cells.
#' @export
#'
#' @examples
#' library(duckh3)
#' ddbh3_max_grid_disk_size(k = 2)
ddbh3_max_grid_disk_size <- function(k = 1, conn = NULL) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_integer_scalar(k, "k")
  duckspatial:::assert_numeric_interval(k, 0, 1500, "k")

  # 1. Ensure connection exists
  if (is.null(conn)) {
    conn <- ddbh3_default_conn(threads = 1)
  }

  # 2. Query DuckDB for the scalar result
  query <- glue::glue("SELECT h3_max_grid_disk_size({k}) AS max_size;")
  res <- DBI::dbGetQuery(conn, query)
  
  return(as.integer(res$max_size[1]))
}





