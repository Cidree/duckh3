

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


create_ddbh3_default_macros <- function() {
  create_ddbh3_macros(duckspatial:::ddbs_default_conn())
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
                  WHERE table_name = '{tbl_name}' 
                  AND column_name = '{column}'")
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
#   conn      <- duckspatial:::ddbs_default_conn()
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
  conn      <- duckspatial:::ddbs_default_conn()
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


#' Build a LATERAL subquery yielding one row per (feature, intersecting h3
#' cell) for POLYGON/MULTIPOLYGON features. MULTI* geometries are split with
#' ST_Dump so the experimental polyfill only ever sees single polygons; the
#' outer DISTINCT dedupes cells shared across parts. `src.{x_geom}` must be
#' in scope at the call site (this is meant to be used inside a `LATERAL (...)`
#' or a correlated subquery against a `src` alias).
#' @noRd
build_polygon_cells_lateral <- function(x_geom, resolution, containment) {
  glue::glue("
    SELECT DISTINCT pc.h3
    FROM (
      SELECT (unnest(ST_Dump(src.{x_geom}))).geom AS geom
    ) AS parts,
    LATERAL (
      SELECT unnest(
        h3_polygon_wkt_to_cells_experimental(
          ST_AsText(parts.geom), {resolution}, '{containment}'
        )
      ) AS h3
    ) AS pc
  ")
}


#' Same as [build_polygon_cells_lateral()], for LINESTRING/MULTILINESTRING
#' features. A line has zero width, so there is no native line-to-cells: a
#' candidate superset is generated by buffering the line by `buffer_scale`
#' times one cell's footprint (measured in degrees at the feature's own
#' location, so it stays latitude-correct), the buffer is polyfilled, and the
#' result is trimmed back to the exact intersecting set with `ST_Intersects`
#' against the ORIGINAL line. The buffer only needs to be generous, never
#' precise, because the exact predicate does the trimming.
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
                       ST_Y(ST_Centroid(src.{x_geom})),
                       ST_X(ST_Centroid(src.{x_geom})),
                       {resolution}
                     )
                   )
                 )
               ) AS env
      ) AS e
    ) AS r,
    LATERAL (
      SELECT (unnest(ST_Dump(ST_Buffer(src.{x_geom}, r.buf)))).geom AS geom
    ) AS parts,
    LATERAL (
      SELECT unnest(
        h3_polygon_wkt_to_cells_experimental(
          ST_AsText(parts.geom), {resolution}, '{containment}'
        )
      ) AS h3
    ) AS pc
    WHERE ST_Intersects(
      src.{x_geom},
      ST_GeomFromWKB(h3_cell_to_boundary_wkb(pc.h3))
    )
  ")
}