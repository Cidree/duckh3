
template_h3_base <- function(
    x,
    conn = NULL,
    name = NULL,
    new_column = "h3string",
    overwrite = FALSE,
    quiet = FALSE,
    fun = NULL
) {

  ## 0. Handle errors
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")

  # 1. Manage connection to DB

  ## 1.1. Pre-extract attributes (CRS and geometry column name)
  ## if the input is not spatial, crs_x and sf_col_x will be NULL and
  ## it will handled by downstream functions
  crs_x    <- tryCatch(
    suppressWarnings(duckspatial::ddbs_crs(x, conn)), 
    error = function(e) NULL
  )
  sf_col_x <- attr(x, "sf_column")

  ## 1.2. Normalize inputs: coerce tbl_duckdb_connection to duckspatial_df,
  ## validate character table names
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))


  # 2. Manage connection to DB

  ## 2.1. Resolve connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  ## register cleanup of the connection
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 2.2. Get query list of table names
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  ## 2.3. Install and load h3 on target connection
  ## TODO - add argument in duckspatial:::resolve_spatial_connections() to manage it
  duckspatial::ddbs_install(target_conn, upgrade = TRUE, quiet = TRUE, extension = "h3", community = TRUE)
  duckspatial::ddbs_load(target_conn, quiet = TRUE, extension = "h3")


  # 3. Prepare parameters for the query

  ## 3.1. Get names of geometry columns (use saved sf_col_x from before transformation)
  ## since the input of this function can be a non-spatial data frame, x_geom can return
  ## an empty value
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  if (length(x_geom != 0)) duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 3.2. Get names of the rest of the columns
  x_rest <- duckspatial:::get_geom_name(
    target_conn,
    x_list$query_name,
    rest = TRUE,
    collapse = TRUE
  )

  ## 3.3. Build the base query
  geom_clause <- if (length(x_geom) > 0) paste0(", ", x_geom) else ""
  base.query <- glue::glue("
    SELECT
      {x_rest}
      {fun} as {new_column}
      {geom_clause}
    FROM
      {x_list$query_name};
  ")


  # 4. if name is not NULL
  if (!is.null(name)) {

    ## convenient names of table and/or schema.table
    name_list <- duckspatial:::get_query_name(name)

    ## handle overwrite
    duckspatial:::overwrite_table(name_list$query_name, target_conn, quiet, overwrite)

    ## create query (no st_as_text)
    tmp.query <- glue::glue("
      CREATE TABLE {name_list$query_name} AS
      {base.query}
    ")
    ## execute query
    DBI::dbExecute(target_conn, tmp.query)
    duckspatial:::feedback_query(quiet)
    return(invisible(TRUE))

  }

  
  # 5. Apply geospatial operation
  result <- duckspatial:::ddbs_handle_query(
      query      = base.query,
      conn       = target_conn,
      mode       = "duckspatial",
      crs        = crs_x,
      crs_column = "crs_duckspatial",
      x_geom     = x_geom
  )
  
  return(result)

}



template_h3_to_spatial <- function(
    x,
    conn = NULL,
    name = NULL,
    output = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    fun = NULL
) {

  ## 0. Handle errors
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")

  # 1. Manage connection to DB

  ## 1.1. Pre-extract geometry column name to overwrite, if present
  sf_col_x <- attr(x, "sf_column")

  ## 1.2. Normalize inputs: coerce tbl_duckdb_connection to duckspatial_df,
  ## validate character table names
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))

  # 2. Manage connection to DB

  ## 2.1. Resolve connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  ## register cleanup of the connection
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 2.2. Get query list of table names
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  ## 2.3. Install and load h3 on target connection
  duckspatial::ddbs_install(target_conn, upgrade = TRUE, quiet = TRUE, extension = "h3", community = TRUE)
  duckspatial::ddbs_load(target_conn, quiet = TRUE, extension = "h3")


  # 3. Prepare parameters for the query

  ## 3.1. Get names of geometry columns (use saved sf_col_x from before transformation)
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  if (length(x_geom != 0)) duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 3.2. Get names of the rest of the columns
  x_rest <- duckspatial:::get_geom_name(
    target_conn,
    x_list$query_name,
    rest = TRUE,
    collapse = TRUE
  )

  ## 3.3. Build the base query
  x_geom <- if (length(x_geom) > 0) x_geom else "geometry"
  base.query <- glue::glue("
    SELECT
      {x_rest}
      {fun} as {x_geom}
    FROM
      {x_list$query_name};
  ")


  # 4. if name is not NULL
  if (!is.null(name)) {

    ## convenient names of table and/or schema.table
    name_list <- duckspatial:::get_query_name(name)

    ## handle overwrite
    duckspatial:::overwrite_table(name_list$query_name, target_conn, quiet, overwrite)

    ## create query (no st_as_text)
    tmp.query <- glue::glue("
      CREATE TABLE {name_list$query_name} AS
      {base.query};
    ")
    ## execute query
    DBI::dbExecute(target_conn, tmp.query)
    duckspatial:::feedback_query(quiet)
    return(invisible(TRUE))

  }

  
  # 5. Apply geospatial operation
  result <- duckspatial:::ddbs_handle_query(
      query      = base.query,
      conn       = target_conn,
      mode       = "duckspatial",
      crs        = "EPSG:4326",
      crs_column = "crs_duckspatial",
      x_geom     = x_geom
  )
  
  return(result)

}
