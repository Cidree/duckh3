
#' Template for main h3 operations
#'
#' @template x
#' @template new_column
#' @template conn_null
#' @template name
#' @template overwrite
#' @template quiet
#' @param fun The duckdb function to use
#' @param other_params string with other function-specific parameters
#' 
#' @keywords internal
#' @noRd
template_h3_base <- function(
    x,
    new_column = "h3string",
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    fun = NULL,
    base_fun = NULL
) {

  ## First, try vectorized option
  if (is.null(conn) && (is.character(x) | is.numeric(x)) && !is.null(base_fun)) {
    res <- get_vectorized_result(x, base_fun)
    return(res)
  }

  # 0. Validate inputs
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")


  # 1. Prepare inputs

  ## 1.1. Pre-extract CRS  
  sf_col_x <- attr(x, "sf_column")
  
  ## 1.2. Normalize inputs (coerce tbl_duckdb_connection to duckspatial_df, 
  ## validate character table names)
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))

  ## 1.3. Extract CRS
  crs_x    <- tryCatch(
    suppressWarnings(duckspatial::ddbs_crs(x, conn)), 
    error = function(e) NULL
  )

  ## 1.4. Resolve spatial connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn, quiet = quiet)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  ## register cleanup of the connection
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 1.5. Get list with query names for the input data
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  ## 1.6. Install and load h3 on target connection
  ## TODO - add argument in duckspatial:::resolve_spatial_connections() to manage it
  # duckspatial::ddbs_install(target_conn, upgrade = FALSE, quiet = TRUE, extension = "h3")
  # duckspatial::ddbs_load(target_conn, quiet = TRUE, extension = "h3")


  # 2. Prepare the query

  ## 2.1. Get names of geometry columns (use saved sf_col_x from before transformation)
  ## since the input of this function can be a non-spatial data frame, x_geom can return
  ## an empty value
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  if (length(x_geom != 0)) duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 2.2. Build the base query
  geom_clause <- if (length(x_geom) > 0) {
    glue::glue("
      * EXCLUDE {x_geom},
      {fun} as {new_column},
      {duckspatial:::build_geom_query(x_geom, name, crs_x, 'duckspatial')} AS {x_geom}"
    )
  } else {
    glue::glue("*, {fun} as {new_column}")
  }
  base.query <- glue::glue("
    SELECT
      {geom_clause}
    FROM
      {x_list$query_name};
  ")

  # 3. Table creation if name is provided, or 
  # create duckspatial_df or sf object if name is NULL
  if (!is.null(name)) {
    duckspatial:::create_duckdb_table(
      conn      = target_conn,
      name      = name,
      query     = base.query,
      overwrite = overwrite,
      quiet     = quiet
    )
  } else {
   duckspatial::: ddbs_handle_query(
      query  = base.query,
      conn   = target_conn,
      mode   = "duckspatial",
      crs    = crs_x,
      x_geom = x_geom
    )
  }

}



template_h3_to_spatial <- function(
    x,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    fun = NULL,
    base_fun = NULL
) {

  # TODO
  # First, try vectorized option
  if (is.null(conn) && is.character(x) && !is.null(base_fun)) {
    res <- get_vectorized_result(x, base_fun)
    return(res)
  }

  # 0. Validate inputs
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")

  ## 1.1. Pre-extract CRS  
  sf_col_x <- attr(x, "sf_column")
  
  ## 1.2. Normalize inputs (coerce tbl_duckdb_connection to duckspatial_df, 
  ## validate character table names)
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))

  ## 1.3. Extract CRS
  crs_x    <- tryCatch(
    suppressWarnings(duckspatial::ddbs_crs(x, conn)), 
    error = function(e) NULL
  )

  ## 1.4. Resolve spatial connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn, quiet = quiet)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  ## register cleanup of the connection
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 1.5. Get list with query names for the input data
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  ## 1.6. Install and load h3 on target connection
  # duckspatial::ddbs_install(target_conn, upgrade = FALSE, quiet = TRUE, extension = "h3")
  # duckspatial::ddbs_load(target_conn, quiet = TRUE, extension = "h3")


  # 2. Prepare the query

  ## 2.1. Get the geometry column name (try to extract from attributes, if not 
  ## available get it from the database)
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  if (length(x_geom != 0)) duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 3.3. Build the columns clause
  if (length(x_geom) == 0) {
    x_geom <- "geometry"
    cols_clause <- glue::glue("*, {duckspatial:::build_geom_query(fun, name, 'EPSG:4326', 'duckspatial')} AS geometry")
  } else {
    cols_clause <- glue::glue("* REPLACE ({duckspatial:::build_geom_query(fun, name, crs_x, 'duckspatial')} AS {x_geom})")
  }

  ## 3.3. Build the base query
  base.query <- glue::glue("
    SELECT
      {cols_clause}
    FROM
      {x_list$query_name};
  ")


  # 3. Table creation if name is provided, or 
  # create duckspatial_df or sf object if name is NULL
  if (!is.null(name)) {
    duckspatial:::create_duckdb_table(
      conn      = target_conn,
      name      = name,
      query     = base.query,
      overwrite = overwrite,
      quiet     = quiet
    )
  } else {
    duckspatial:::ddbs_handle_query(
      query  = base.query,
      conn   = target_conn,
      mode   = "duckspatial",
      crs    = "EPSG:4326",
      x_geom = x_geom
    )
  }

}
