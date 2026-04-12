#' Convert H3 cell indexes to vertex representations
#'
#' Convert H3 cell indexes stored as strings or unsigned 64-bit integers
#' (`UBIGINT`) to their vertex representations
#'
#'
#' @template x
#' @param n Integer. Vertex number to retrieve. Must be in the range 0–5 for
#'   hexagons and 0–4 for pentagons. Only used in `ddbh3_h3_to_vertex()`.
#' @template h3
#' @template h3vertex
#' @template new_column
#' @template conn_null
#' @template name
#' @template nested
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The functions cover the full vertex workflow:
#' * `ddbh3_h3_to_vertex()` returns a single vertex of an H3 cell, identified
#'   by its vertex number `n` (0–5 for hexagons, 0–4 for pentagons), as an H3
#'   vertex string
#' * `ddbh3_h3_to_vertexes()` returns all vertices of an H3 cell as H3 vertex
#'   strings — either nested (one row per cell) or unnested (one row per vertex)
#'   depending on `nested`
#' * `ddbh3_vertex_to_lat()` returns the latitude of an H3 vertex string
#' * `ddbh3_vertex_to_lon()` returns the longitude of an H3 vertex string
#' * `ddbh3_vertex_to_spatial()` converts H3 vertex strings to spatial point
#'   geometries. If the input column is nested, vertices are automatically
#'   unnested and aggregated into a `MULTIPOINT` geometry per cell
#'
#' @template returns_tbl
#'
#' @name ddbh3_vertex
#' @aliases ddbh3_h3_to_vertex ddbh3_h3_to_vertexes ddbh3_vertex_to_spatial
#'
#' @examples
#' ## Load needed packages
#' library(duckh3)
#' library(duckspatial)
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
#' ## TO VERTEX ---------------
#' 
#' ## Add second vertex
#' vertex_2_tbl <- ddbh3_h3_to_vertex(points_tbl, n = 2)
#' 
#' ## Add add vertexes (unnested)
#' vertexes_tbl <- ddbh3_h3_to_vertexes(points_tbl)
#' 
#' ## Add add vertexes (nested)
#' vertexes_nested_tbl <- ddbh3_h3_to_vertexes(points_tbl, nested = TRUE)
#' 
#' ## Add some vertexes with with mutate
#' points_tbl |> 
#'   mutate(
#'     v1 = ddbh3_h3_to_vertex(h3string, 1),
#'     v3 = ddbh3_h3_to_vertex(h3string, 3)
#'   )
#' 
#' ## VERTEX TO LON/LAT ------
#' 
#' ## Add coords
#' coords_vertex_tbl <- vertex_2_tbl |> 
#'   ddbh3_vertex_to_lon(new_column = "lon_v2") |> 
#'   ddbh3_vertex_to_lat(new_column = "lat_v2")
#' 
#' ## Add coords in mutate
#' vertex_2_tbl |> 
#'   mutate(
#'     lon_v2 = ddbh3_vertex_to_lon(h3vertex),
#'     lat_v2 = ddbh3_vertex_to_lat(h3vertex)
#'   )
#' 
#' ## VERTEX TO SPATIAL ------
#' 
#' ## Convert unnested vertexes (returns POINTS)
#' ddbh3_h3_to_vertexes(points_tbl) |> 
#'   ddbh3_vertex_to_spatial()
#' 
#' 
#' ## Convert nested vertexes (returns MULTIPOINTS)
#' ddbh3_h3_to_vertexes(points_tbl, nested = TRUE) |> 
#'   ddbh3_vertex_to_spatial()
NULL




#' @rdname ddbh3_vertex
#' @export
ddbh3_h3_to_vertex <- function(
    x,
    n = 0,
    h3 = "h3string",
    new_column = "h3vertex",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_integer_scalar(n, "n")
  duckspatial:::assert_numeric_interval(n, 0, 5, "n")


  # 1. Build parameters string
  built_fun <- glue::glue("h3_cell_to_vertex({h3}, {n})")


  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = glue::glue("h3_cell_to_vertex(x, {n})")
  ) 

}



#' @rdname ddbh3_vertex
#' @export
ddbh3_vertex_to_lon <- function(
    x,
    h3vertex = "h3vertex",
    new_column = "lon_vertex",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3vertex, "h3vertex")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_vertex_to_lng({h3vertex})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_vertex_to_lng(x)"
  )

}





#' @rdname ddbh3_vertex
#' @export
ddbh3_vertex_to_lat <- function(
    x,
    h3vertex = "h3vertex",
    new_column = "lat_vertex",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3vertex, "h3vertex")

  # 1. Build parameters string
  built_fun <- glue::glue("h3_vertex_to_lat({h3vertex})")

  # 2. Pass to template
  template_h3_base(
    x = x,
    conn = conn,
    name = name,
    new_column = new_column,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun,
    base_fun = "h3_vertex_to_lat(x)"
  ) 

}





#' @rdname ddbh3_vertex
#' @export
ddbh3_h3_to_vertexes <- function(
    x,
    h3 = "h3string",
    new_column = "h3vertex",
    conn = NULL,
    name = NULL,
    nested = FALSE,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3, "h3")
  duckspatial:::assert_logic(nested, "nested")

  # 1. Build parameters string
  if (isTRUE(nested)) {
    built_fun <- glue::glue("h3_cell_to_vertexes({h3})")
  } else {
    built_fun <- glue::glue("UNNEST(h3_cell_to_vertexes({h3}))")
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
    base_fun = "h3_cell_to_vertexes(x)"
  ) 

}





#' @rdname ddbh3_vertex
#' @export
ddbh3_vertex_to_spatial <- function(
    x,
    h3vertex = "h3vertex",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  
  
  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(h3vertex, "h3vertex")


  # 1. Build parameters string

  ## 1.1. Check if it's nested
  is_nested <- check_nested_column(x, h3vertex)
  if (is_nested) {
  built_fun <- glue::glue("
    ST_POINT(
      h3_vertex_to_lng(UNNEST({h3vertex})),
      h3_vertex_to_lat(UNNEST({h3vertex}))
    )  
  ")
  } else {
  built_fun <- glue::glue("
    ST_POINT(
      h3_vertex_to_lng({h3vertex}),
      h3_vertex_to_lat({h3vertex})
    )  
  ")
  }


  # 2. Pass to template
  result <- template_h3_to_spatial(
    x = x,
    conn = conn,
    name = name,
    overwrite = overwrite,
    quiet = quiet,
    fun = built_fun
  )    


  # 3. Union in multipoint if it's nested
  if (is_nested) {
    result_crs <- result |> 
      dplyr::mutate(crs_duckspatial = "EPSG:4326")
    cols <- setdiff(colnames(result_crs), c("crs_duckspatial", "geometry"))
    duckspatial::ddbs_union_agg(result_crs, cols)
  } else {
    result
  }

}


