
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






#' Template for polygon/line -> spatial H3 hexagons
#'
#' One output row per (input feature, intersecting H3 cell); the geometry
#' column is replaced with the cell's hexagon boundary.
#'
#' @param geom_family Either `"POLYGON"` or `"LINESTRING"` — controls which
#' geometry assertion and cells-lateral builder is used.
#' @keywords internal
#' @noRd
template_h3_geom_to_spatial <- function(
    x,
    resolution,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    containment = "overlap",
    buffer_scale = 1,
    geom_family = c("POLYGON", "LINESTRING")
) {

  geom_family <- match.arg(geom_family)

  # 0. Validate inputs
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")
  duckspatial:::assert_geom_type(x = x, conn = conn, geom = geom_family, multi = TRUE)
  containment <- assert_containment(containment)

  # 1. Manage connection to DB

  ## 1.1. Pre-extract geometry column name + CRS check (must be EPSG:4326)
  crs_x    <- duckspatial::ddbs_crs(x, conn)
  sf_col_x <- attr(x, "sf_column")

  if (crs_x$input != "EPSG:4326") {
    cli::cli_abort("The CRS of the input must be {.val EPSG:4326}, not {.val {crs_x$input}}.")
  }

  ## 1.2. Normalize inputs: coerce tbl_duckdb_connection to duckspatial_df,
  ## validate character table names
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))

  # 2. Manage connection to DB

  ## 2.1. Resolve connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn, quiet = quiet)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 2.2. Get query list of table names
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  # 3. Prepare parameters for the query

  ## 3.1. Get names of geometry columns (use saved sf_col_x from before transformation)
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 3.2. Get names of the rest of the columns
  x_rest <- duckspatial:::get_geom_name(
    target_conn,
    x_list$query_name,
    rest = TRUE,
    collapse = TRUE
  )

  ## 3.3. Build the per-feature cells LATERAL and the base query
  cells_lateral <- if (geom_family == "POLYGON") {
    build_polygon_cells_lateral(x_geom, resolution, containment)
  } else {
    build_line_cells_lateral(x_geom, resolution, containment, buffer_scale)
  }

  base.query <- glue::glue("
    SELECT
      {x_rest}
      ST_GeomFromWKB(h3_cell_to_boundary_wkb(cells.h3)) AS {x_geom}
    FROM
      {x_list$query_name} AS src,
    LATERAL (
      {cells_lateral}
    ) AS cells;
  ")

  # 4. Table creation if name is provided, or
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



#' Template for polygon/line -> H3 list column
#'
#' One output row per input feature; `new_column` holds the list of H3 cells
#' (string or `UBIGINT`) intersecting that feature. Geometry is preserved.
#'
#' @inheritParams template_h3_geom_to_spatial
#' @keywords internal
#' @noRd
template_h3_geom_to_h3 <- function(
    x,
    resolution,
    new_column = "h3string",
    h3_format = "string",
    containment = "overlap",
    buffer_scale = 1,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    geom_family = c("POLYGON", "LINESTRING")
) {

  geom_family <- match.arg(geom_family)

  # 0. Validate inputs
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_character_scalar(h3_format, "h3_format")
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")
  duckspatial:::assert_geom_type(x = x, conn = conn, geom = geom_family, multi = TRUE)
  containment <- assert_containment(containment)
  if (!h3_format %in% c("string", "bigint")) {
    cli::cli_abort("The {.arg h3_format} is not valid. Valid options: {.val {c('string', 'bigint')}}")
  }

  # 1. Prepare inputs

  ## 1.1. Pre-extract geometry column name + CRS check
  crs_x    <- duckspatial::ddbs_crs(x, conn)
  sf_col_x <- attr(x, "sf_column")

  if (crs_x$input != "EPSG:4326") {
    cli::cli_abort("The CRS of the input must be {.val EPSG:4326}, not {.val {crs_x$input}}.")
  }

  ## 1.2. Normalize inputs
  x <- suppressWarnings(duckspatial:::normalize_spatial_input(x, conn))

  ## 1.3. Resolve connections and handle imports
  resolve_conn <- duckspatial:::resolve_spatial_connections(x, y = NULL, conn = conn)
  target_conn  <- resolve_conn$conn
  x            <- resolve_conn$x
  on.exit(resolve_conn$cleanup(), add = TRUE)

  ## 1.4. Get query list of table names
  x_list <- duckspatial:::get_query_list(x, target_conn)
  on.exit(x_list$cleanup(), add = TRUE)

  # 2. Prepare the query

  ## 2.1. Get names of geometry columns
  x_geom <- sf_col_x %||% duckspatial:::get_geom_name(target_conn, x_list$query_name)
  duckspatial:::assert_geometry_column(x_geom, x_list)

  ## 2.2. Build the per-feature cells LATERAL as a correlated subquery,
  ## producing a distinct list of bigint cells, cast to strings if requested
  cells_lateral <- if (geom_family == "POLYGON") {
    build_polygon_cells_lateral(x_geom, resolution, containment)
  } else {
    build_line_cells_lateral(x_geom, resolution, containment, buffer_scale)
  }

  list_expr <- glue::glue("(SELECT list_distinct(list(agg.h3)) FROM ({cells_lateral}) AS agg)")
  if (h3_format == "string") {
    list_expr <- glue::glue("list_transform({list_expr}, cell -> h3_h3_to_string(cell))")
  }

  ## 2.3. Build the base query
  base.query <- glue::glue("
    SELECT
      src.* EXCLUDE {x_geom},
      {list_expr} AS {new_column},
      {duckspatial:::build_geom_query(x_geom, name, crs_x, 'duckspatial')} AS {x_geom}
    FROM
      {x_list$query_name} AS src;
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