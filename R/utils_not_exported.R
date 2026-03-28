

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
get_vectorized_result <- function(x, fun) {

  ## Create a random view name
  conn      <- duckspatial:::ddbs_default_conn()
  view_name <- duckspatial:::ddbs_temp_view_name()

  ## Register the data as a view
  duckdb::duckdb_register(conn, view_name, data.frame(x = x))
  on.exit(duckdb::duckdb_unregister(conn, view_name))

  ## Apply function, and return the pulled vector
  res <- dplyr::tbl(conn, view_name) |> 
    dplyr::mutate(res = dbplyr::sql(glue::glue("{fun}"))) |> 
    dplyr::pull("res")

  if (any(is.na(res))) {
    cli::cli_warn("Some elements of {.arg x} are invalid. Returning NA.")
  }

  return(res)

}

