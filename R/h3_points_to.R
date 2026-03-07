#' Convert spatial points to H3 cell representations
#'
#' Convert spatial point geometries into H3 cell representations at a specified
#' resolution. Input must be an `duckspatial_df`, `sf`, or table with point
#' geometries
#'
#' @template x
#' @template resolution
#' @template conn_null
#' @template name
#' @template new_column
#' @param h3_format Character. Output format for the H3 cell index. Either
#' `"string"` (default) or `"bigint"`. Only used in `ddbh3_points_to_h3()`.
#' @template overwrite
#' @template quiet
#' 
#' @details
#' The two functions differ in the output format:
#' * `ddbh3_points_to_h3()` returns the H3 cell index containing each point,
#'   either as a string or `UBIGINT` depending on `h3_format`
#' * `ddbh3_points_to_spatial()` returns the H3 cell hexagon polygon containing
#'   each point as a spatial geometry
#'
#' @template returns_tbl
#'
#' @name ddbh3_points_to
#' @aliases ddbh3_points_to_h3 ddbh3_points_to_spatial
#'
#' @examples
#' \dontrun{
#' ## Load needed packages
#' library(duckh3)
#' library(duckspatial)
#' 
#' ## Load example data
#' points_tbl <- read.csv(
#'   system.file("extdata/example_pts.csv", package = "duckh3")
#' )
#' 
#' ## Convert to duckspatial_df
#' points_ddbs <- ddbs_as_spatial(points_tbl)
#' 
#' ## TO H3 strings/ubigint ------------
#' 
#' ## Add column with h3 strings at resolution 8
#' points_strings_ddbs <- ddbh3_points_to_h3(points_ddbs, 8)
#' 
#' ## Add column with h3 ubigint at resolution 10
#' points_bigint_ddbs <- ddbh3_points_to_h3(
#'   points_ddbs, 
#'   resolution = 8,
#'   new_column = "h3bigint",
#'   h3_format = "bigint"
#' )
#' 
#' ## TO SPATIAL -----------------
#' 
#' ## Convert from POINTS to H3 POLYGONS of res 8
#' polygons_8_ddbs <- ddbh3_points_to_spatial(points_ddbs, 8)
#' 
#' ## Collect as sf
#' polygons_8_sf <- ddbs_collect(polygons_8_ddbs)
#' }
NULL





#' @rdname ddbh3_points_to
#' @export
ddbh3_points_to_spatial <- function(
    x,
    resolution,
    conn = NULL,
    name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")
  duckspatial:::assert_geom_type(x = x, conn = conn, geom = "POINT", multi = TRUE)

  # 1. Manage connection to DB

  ## 1.1. Pre-extract geometry column name to overwrite, if present
  crs_x    <- duckspatial::ddbs_crs(x, conn)
  sf_col_x <- attr(x, "sf_column")

  if (crs_x$input != "EPSG:4326") {
    cli::cli_abort("The CRS of the input must be {.val EPSG:4326}, not {.val crs_x$input}.")
  }


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
      ST_GeomFromWKB(
        h3_cell_to_boundary_wkb(
          h3_latlng_to_cell(
            ST_Y({x_geom}),
            ST_X({x_geom}),
            {resolution}
          )
        )
      ) as {x_geom}
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





#' @rdname ddbh3_points_to
#' @export
ddbh3_points_to_h3 <- function(
    x,
    resolution,
    conn = NULL,
    name = NULL,
    new_column = "h3string",
    h3_format = "string",
    overwrite = FALSE,
    quiet = FALSE
) {

  # 0. Handle function-specific errors
  duckspatial:::assert_character_scalar(new_column, "new_column")
  duckspatial:::assert_character_scalar(h3_format, "h3_format")
  duckspatial:::assert_conn_character(conn, x)
  duckspatial:::assert_name(name)
  duckspatial:::assert_logic(overwrite, "overwrite")
  duckspatial:::assert_logic(quiet, "quiet")
  duckspatial:::assert_integer_scalar(resolution, "resolution")
  duckspatial:::assert_numeric_interval(resolution, 0, 15, "resolution")
  duckspatial:::assert_geom_type(x = x, conn = conn, geom = "POINT", multi = TRUE)

  # 1. Manage connection to DB

  ## 1.1. Pre-extract geometry column name to overwrite, if present
  crs_x    <- duckspatial::ddbs_crs(x, conn)
  sf_col_x <- attr(x, "sf_column")

  if (crs_x$input != "EPSG:4326") {
    cli::cli_abort("The CRS of the input must be {.val EPSG:4326}, not {.val crs_x$input}.")
  }


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
  st_function <- switch(
    h3_format,
    "string" = glue::glue("h3_latlng_to_cell_string"),
    "bigint" = glue::glue("h3_latlng_to_cell"),
    cli::cli_abort("The {.arg h3_format} is not valid. Valid options: {.val {c('string', 'bigint')}}")
  )
  base.query <- glue::glue("
    SELECT
      {x_rest}
      {st_function}(
        ST_Y({x_geom}),
        ST_X({x_geom}),
        {resolution}
      ) as {new_column},
      {x_geom}
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
