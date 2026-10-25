

create_ddbh3_macros <- function(conn) {

  macros <- list(

    # ── lonlat to --------------------------------------------------------------
    "CREATE OR REPLACE MACRO ddbh3_lonlat_to_h3(lon, lat, resolution) AS
      h3_latlng_to_cell_string(lat, lon, CAST(resolution AS INTEGER))",

    # ── h3 to  -----------------------------------------------------------------
    "CREATE OR REPLACE MACRO ddbh3_bigint_to_strings(h3) AS
      h3_h3_to_string(h3)",

    "CREATE OR REPLACE MACRO ddbh3_h3_to_lat(h3) AS
      h3_cell_to_lat(h3)",

    "CREATE OR REPLACE MACRO ddbh3_h3_to_lon(h3) AS
      h3_cell_to_lng(h3)",

    "CREATE OR REPLACE MACRO ddbh3_strings_to_bigint(h3) AS
      h3_string_to_h3(h3)",

    # ── H3 properties ----------------------------------------------------------
    "CREATE OR REPLACE MACRO ddbh3_get_resolution(h3) AS
      h3_get_resolution(h3)",

    "CREATE OR REPLACE MACRO ddbh3_is_pentagon(h3) AS
      h3_is_pentagon(h3)",

    "CREATE OR REPLACE MACRO ddbh3_is_res_class_iii(h3) AS
      h3_is_res_class_iii(h3)",

    "CREATE OR REPLACE MACRO ddbh3_is_h3(h3) AS
      h3_is_valid_cell(h3)",

    "CREATE OR REPLACE MACRO ddbh3_is_vertex(h3vertex) AS
      h3_is_valid_vertex(h3vertex)",

    # ── H3 hierarchy -----------------------------------------------------------
    "CREATE OR REPLACE MACRO ddbh3_get_parent(h3, resolution) AS
      h3_cell_to_parent(h3, CAST(resolution AS INTEGER))",

    "CREATE OR REPLACE MACRO ddbh3_get_children(h3, resolution) AS
      h3_cell_to_children(h3, CAST(resolution AS INTEGER))",

    "CREATE OR REPLACE MACRO ddbh3_get_center_child(h3, resolution) AS
      h3_cell_to_center_child(h3, CAST(resolution AS INTEGER))",

    "CREATE OR REPLACE MACRO ddbh3_get_n_children(h3, resolution) AS
      h3_cell_to_children_size(h3, CAST(resolution AS INTEGER))",

    "CREATE OR REPLACE MACRO ddbh3_get_child_pos(h3, resolution) AS
      h3_cell_to_child_pos(h3, CAST(resolution AS INTEGER))",
      
    "CREATE OR REPLACE MACRO ddbh3_get_icosahedron_faces(h3) AS
      h3_get_icosahedron_faces(h3)",

    # ── H3 vertices -------------------------------------------------------------
    "CREATE OR REPLACE MACRO ddbh3_h3_to_vertex(h3, n) AS
      h3_cell_to_vertex(h3, CAST(n AS INTEGER))",

    "CREATE OR REPLACE MACRO ddbh3_vertex_to_lat(h3vertex) AS
      h3_vertex_to_lat(h3vertex)",

    "CREATE OR REPLACE MACRO ddbh3_vertex_to_lon(h3vertex) AS
      h3_vertex_to_lng(h3vertex)"

  )

  invisible(lapply(macros, DBI::dbExecute, conn = conn))

}


#' Pin the pre-v2.0 axis order on a connection
#'
#' Since DuckDB v2.0, spheroid functions such as `ST_Area_Spheroid()` error
#' unless `geometry_always_xy` is set explicitly. duckspatial's measure
#' functions (e.g. `duckspatial::ddbs_area()`) call them as
#' `ST_Area_Spheroid(ST_FlipCoordinates(geom))`, i.e. they already convert
#' lon/lat to the pre-v2.0 [LATITUDE, LONGITUDE] convention. Setting `true`
#' would flip the axes twice and return wrong areas (or NA for |lon| > 90), so
#' `false` (the pre-v2.0 behaviour) is the value that matches duckspatial.
#' The setting comes from the spatial extension and already exists in DuckDB
#' v1.5; `try()` keeps older or unusual setups working.
#' @keywords internal
#' @noRd
set_geometry_axis_order <- function(conn) {
  try(DBI::dbExecute(conn, "SET geometry_always_xy = false"), silent = TRUE)
  invisible(conn)
}


create_ddbh3_default_macros <- function() {
  create_ddbh3_macros(duckspatial::ddbs_default_conn())
}



check_nested_column <- function(x, column) {

  ## For lazy tables we query the column type. However, the way of
  ## finding the source conn and table is different depending of the
  ## object type
  if (inherits(x, "duckspatial_df") | inherits(x, "tbl_duckdb_connection")) {
    if (inherits(x, "duckspatial_df")) {
      conn     <- attr(x, "source_conn")
      tbl_name <- attr(x, "source_table")
    } else {
      conn <- dbplyr::remote_con(x)
      tbl_name <- dbplyr::remote_name(x)

      ## If the name is null, we need to compute the previous lazy
      ## table to obtain a table name to query
      if (is.null(tbl_name)) {
        tbl_comp <- dplyr::compute(x)
        tbl_name <- dbplyr::remote_name(tbl_comp)
      }
    }

    col_type <- DBI::dbGetQuery(
      conn,
      glue::glue("SELECT data_type FROM information_schema.columns 
                  WHERE table_name = {DBI::dbQuoteString(conn, tbl_name)} 
                  AND column_name = {DBI::dbQuoteString(conn, column)}")
    )$data_type

    return(grepl("\\[\\]", col_type))

    ## For data.frame and sf we look for a list of characters
  } else if (inherits(x, "data.frame") | inherits(x, "sf")) {
    
    if (inherits(x[[column]], "list")) return(TRUE) else return(FALSE)

    ## For every other case, we consider unnested and let downstream
    ## processes to manage it
  } else {
    return(FALSE)
  }
  
}


## e.g. ddbh3_h3_to_lat("8ad02dcc1947fff") 
# get_vectorized_result <- function(x, fun) {

#   ## Create a random view name
#   conn      <- duckspatial::ddbs_default_conn()
#   view_name <- duckspatial:::ddbs_temp_view_name()

#   ## Register the data as a view
#   duckdb::duckdb_register(conn, view_name, data.frame(x = x))
#   on.exit(duckdb::duckdb_unregister(conn, view_name))

#   ## Apply function, and return the pulled vector
#   res <- dplyr::tbl(conn, view_name) |> 
#     dplyr::mutate(res = dbplyr::sql(glue::glue("{fun}"))) |> 
#     dplyr::pull("res")

#   if (any(is.na(res))) {
#     cli::cli_warn("Some elements of {.arg x} are invalid. Returning NA.")
#   }

#   return(res)

# }



get_vectorized_result <- function(x, fun) {

  if (!grepl("h3_is_valid_cell", fun)) {

    if (is.numeric(x) && !bit64::is.integer64(x)) {
      ## plain double: precision already lost upstream, nothing to validate
      cli::cli_abort(c(
        "`x` contains invalid H3 (e.g. {head(x)})",
        "i" = "If `x` originated as plain numeric/double, precision may already be lost",
        "i" = "Recreate `x` as a character h3string, or as int64 using {.code bit64::as.integer64('x')}"
      ))
    }

    if (is.character(x)) {
      all_h3 <- ddbh3_is_h3(x)
      if (isFALSE(all(all_h3))) {
        invalid_h3 <- x[!all_h3]
        cli::cli_abort(c(
          "`x` contains invalid H3 (e.g. {head(invalid_h3)})",
          "*" = "If `x` is a table, `conn` cannot be NULL.",
          "*" = "Check if `x` contain invalid h3strings"
        ))
      }

    } else if (bit64::is.integer64(x)) {
      all_h3 <- ddbh3_is_h3(x)
      if (isFALSE(all(all_h3))) {
        invalid_h3 <- x[!all_h3]
        cli::cli_abort(c(
          "`x` contains invalid H3 (e.g. {head(invalid_h3)})",
          "i" = "If `x` originated as plain numeric/double, precision may already be lost",
          "i" = "Recreate `x` as a character h3string, or as int64 using {.code bit64::as.integer64('x')}"
        ))
      }
    }
  }

  ## Create a random view name
  conn      <- duckspatial::ddbs_default_conn()
  view_name <- duckspatial:::ddbs_temp_view_name()

  duckdb::duckdb_register(conn, view_name, data.frame(x = x))
  on.exit(duckdb::duckdb_unregister(conn, view_name))

  res <- dplyr::tbl(conn, view_name) |> 
    dplyr::mutate(res = dbplyr::sql(glue::glue("{fun}"))) |> 
    dplyr::pull("res")

  if (any(is.na(res))) {
    cli::cli_warn("Some elements of {.arg x} are invalid. Returning NA.")
  }

  return(res)
}




#' Validate the `containment` argument shared by the geometry-to-H3 functions
#' @keywords internal
#' @noRd
assert_containment <- function(containment) {
  switch(
    containment,
    "overlap"      = ,
    "full"         = ,
    "center"       = ,
    "overlap_bbox" = containment,
    cli::cli_abort(
      "The {.arg containment} is not valid. Valid options: {.val {c('overlap', 'full', 'center', 'overlap_bbox')}}"
    )
  )
}


#' Validate the geometry types of an already-prepared input
#'
#' Same check as `duckspatial:::assert_geom_type()`, but it runs on the view
#' returned by `get_query_list()`, so the input is not normalized/registered a
#' second time. Only the offending types are returned by the query.
#' @keywords internal
#' @noRd
assert_geom_type_query <- function(conn, query_name, x_geom, geom, multi = TRUE) {
  if (isTRUE(multi)) geom <- c(geom, paste0("MULTI", geom))
  allowed <- paste0("'", geom, "'", collapse = ", ")
  invalid_types <- DBI::dbGetQuery(conn, glue::glue("
    SELECT DISTINCT ST_GeometryType({quote_ident(x_geom)})::VARCHAR AS type
    FROM {query_name}
    WHERE ST_GeometryType({quote_ident(x_geom)})::VARCHAR NOT IN ({allowed})
  "))$type
  if (length(invalid_types) > 0) {
    cli::cli_abort(c(
      "Invalid geometry type{?s} found: {.val {invalid_types}}",
      i = "Allowed type{?s}: {.val {geom}}"
    ))
  }
  invisible(TRUE)
}


#' Builds polygon cells lateral
#'
#' Build a LATERAL subquery yielding one row per (feature, intersecting h3
#' cell) for POLYGON/MULTIPOLYGON features. MULTI* geometries are split with
#' ST_Dump so the experimental polyfill only ever sees single polygons; the
#' outer DISTINCT dedupes cells shared across parts. `src.{x_geom}` must be
#' in scope at the call site (this is meant to be used inside a `LATERAL (...)`
#' or a correlated subquery against a `src` alias).
#' @keywords internal
#' @noRd
build_polygon_cells_lateral <- function(x_geom, resolution, containment) {
  glue::glue("
    SELECT DISTINCT pc.h3
    FROM (
      SELECT (unnest(ST_Dump(src.{quote_ident(x_geom)}))).geom AS geom
    ) AS parts,
    LATERAL (
      SELECT unnest(
        h3_polygon_wkb_to_cells_experimental(
          ST_AsWKB(parts.geom), {resolution}, '{containment}'
        )
      ) AS h3
    ) AS pc
  ")
}


#' Builds line cells lateral
#'
#' Same as build_polygon_cells_lateral, for LINESTRING/MULTILINESTRING
#' features. A line has zero width, so there is no native line-to-cells: a
#' candidate superset is generated by buffering the line by `buffer_scale`
#' times one cell's footprint (measured in degrees at the feature's own
#' location, so it stays latitude-correct), the buffer is polyfilled, and the
#' result is trimmed back to the exact intersecting set with `ST_Intersects`
#' against the ORIGINAL line. The buffer only needs to be generous, never
#' precise, because the exact predicate does the trimming.
#' @keywords internal
#' @noRd
build_line_cells_lateral <- function(x_geom, resolution, containment, buffer_scale) {
  glue::glue("
    SELECT DISTINCT pc.h3
    FROM (
      SELECT {buffer_scale} * greatest(
               ST_XMax(env) - ST_XMin(env),
               ST_YMax(env) - ST_YMin(env)
             ) AS buf
      FROM (
        SELECT ST_Envelope(
                 ST_GeomFromWKB(
                   h3_cell_to_boundary_wkb(
                     h3_latlng_to_cell(
                       ST_Y(ST_Centroid(src.{quote_ident(x_geom)})),
                       ST_X(ST_Centroid(src.{quote_ident(x_geom)})),
                       {resolution}
                     )
                   )
                 )
               ) AS env
      ) AS e
    ) AS r,
    LATERAL (
      SELECT (unnest(ST_Dump(ST_Buffer(src.{quote_ident(x_geom)}, r.buf)))).geom AS geom
    ) AS parts,
    LATERAL (
      SELECT unnest(
        h3_polygon_wkb_to_cells_experimental(
          ST_AsWKB(parts.geom), {resolution}, '{containment}'
        )
      ) AS h3
    ) AS pc
    WHERE ST_Intersects(
      src.{quote_ident(x_geom)},
      ST_GeomFromWKB(h3_cell_to_boundary_wkb(pc.h3))
    )
  ")
}


#' Checks if the h3 extension is installed for duckh3
#' @template conn_null
#' @noRd
#' @keywords internal
check_installed_h3 <- function(conn = NULL) {

    # 1. Resolve and validate inputs
    duckspatial:::dbConnCheck(conn)

    # 2. Query the extension catalog
    info <- DBI::dbGetQuery(
        conn,
        "SELECT * FROM duckdb_extensions() WHERE extension_name = 'h3'"
    )

    if (nrow(info) == 0) {
        cli::cli_abort(c(
            "i" = "Extension {.val h3} was not found in duckdb_extensions.",
            "*" = "Create a default connection with {.run duckh3::ddbh3_default_conn()} to set it up",
            "*" = "Or create a connection, and install the spatial and h3 extensions manually"
        ))
    }
  
    if (isFALSE(info$installed)) {
         cli::cli_abort(c(
             "i" = "Extension {.val h3} was not found in duckdb_extensions.",
             "*" = "Create a default connection with {.run duckh3::ddbh3_default_conn()} to set it up",
             "*" = "Or create a connection, and install the spatial and h3 extensions manually"
         ))
     }
  
    if (isFALSE(info$loaded)) {
         cli::cli_abort(c(
             "i" = "Extension {.val h3} {info$extension_version} is installed but not loaded",
             "*" = "Create a default connection with {.run duckh3::ddbh3_default_conn()} to set it up"
         ))
     }
  

}



#' Quote a column name as a SQL identifier
#'
#' Wraps `x` in double quotes (escaping embedded ones), so user-supplied column
#' names with spaces, reserved words or quotes are referenced as columns and
#' never executed as SQL.
#'
#' @param x character vector with column names
#'
#' @keywords internal
#' @noRd
#' @returns a character vector with the quoted identifiers
quote_ident <- function(x) {
  as.character(DBI::dbQuoteIdentifier(DBI::ANSI(), x))
}



#' Build the SELECT list that adds (or replaces) `new_column`
#'
#' Returns `* [EXCLUDE (...)], <expr> AS new_column` when `new_column` is not a
#' column of the input, and `* [EXCLUDE (...)] REPLACE (<expr> AS new_column)`
#' when it is, so an existing column is overwritten in place instead of DuckDB
#' adding a duplicate with a `_1` suffix.
#'
#' @template conn_null
#' @param query_name name of the table/view with the input data
#' @template new_column
#' @param expr SQL expression for the new column
#' @param exclude columns to exclude from `*` (e.g. the geometry column)
#' @param star the star expression (e.g. `"src.*"`)
#'
#' @keywords internal
#' @noRd
#' @returns a character string with the SELECT list
build_new_column_select <- function(
    conn,
    query_name,
    new_column,
    expr,
    exclude = character(0),
    star = "*"
) {

  ## Columns of the input (DuckDB identifiers are case-insensitive)
  x_cols <- names(DBI::dbGetQuery(conn, glue::glue("SELECT * FROM {query_name} LIMIT 0")))
  exclude_clause <- if (length(exclude) > 0) {
    glue::glue(" EXCLUDE ({paste(quote_ident(exclude), collapse = ', ')})")
  } else {
    ""
  }

  if (tolower(new_column) %in% tolower(x_cols)) {
    glue::glue("{star}{exclude_clause} REPLACE ({expr} AS {quote_ident(new_column)})")
  } else {
    glue::glue("{star}{exclude_clause}, {expr} AS {quote_ident(new_column)}")
  }
}



#' Create a table from a query, safely overwriting existing tables
#'
#' Wrapper around `duckspatial:::create_duckdb_table()`. When `overwrite = TRUE`,
#' the result is first written to a staging table and only then swapped in
#' place of `name` (inside a transaction). This keeps the source data intact
#' when `name` is the same table that `query` reads from (directly or through
#' a view or lazy query).
#'
#' @template conn_null
#' @template name
#' @param query SQL `SELECT` query that produces the table
#' @template overwrite
#' @template quiet
#'
#' @keywords internal
#' @noRd
#' @returns invisible TRUE
create_h3_table <- function(conn, name, query, overwrite, quiet) {

  ## Without overwrite there's nothing to drop: use the duckspatial helper
  if (!isTRUE(overwrite)) {
    return(duckspatial:::create_duckdb_table(
      conn      = conn,
      name      = name,
      query     = query,
      overwrite = overwrite,
      quiet     = quiet
    ))
  }

  ## Names of the target and of the staging table (same schema as the target)
  name_list     <- duckspatial:::get_query_name(name)
  staging_table <- basename(tempfile(paste0(name_list$table_name, "_ddbh3_staging_")))
  staging_name  <- if (length(name) == 2) {
    paste(name_list$schema_name, staging_table, sep = ".")
  } else {
    staging_table
  }

  ## 1. Materialize the result before touching the target table
  DBI::dbExecute(conn, glue::glue("CREATE TABLE {staging_name} AS {query}"))
  on.exit(
    DBI::dbExecute(conn, glue::glue("DROP TABLE IF EXISTS {staging_name}")),
    add = TRUE
  )

  ## 2. Swap the staging table in place of the target
  DBI::dbWithTransaction(conn, {
    DBI::dbExecute(conn, glue::glue("DROP TABLE IF EXISTS {name_list$query_name}"))
    DBI::dbExecute(
      conn,
      glue::glue("ALTER TABLE {staging_name} RENAME TO {name_list$table_name}")
    )
  })
  if (isFALSE(quiet)) cli::cli_alert_info("Table <{name_list$query_name}> dropped")

  duckspatial:::feedback_query(quiet)
  invisible(TRUE)
}
