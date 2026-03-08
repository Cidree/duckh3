

# create_duckdbh3_macros <- function(conn) {
#   DBI::dbExecute(
#     conn,
#     "CREATE OR REPLACE MACRO ddbh3_lonlat_to_strings(lon, lat, level) AS h3_latlng_to_cell_string(lat, lon, CAST(level AS INTEGER));
#     "
#   )
# }

check_nested_column <- function(x, column) {
  con <- dbplyr::remote_con(x)
  tbl_name <- dbplyr::remote_name(x)
  
  col_type <- DBI::dbGetQuery(
    con,
    glue::glue("SELECT data_type FROM information_schema.columns 
                WHERE table_name = '{tbl_name}' 
                AND column_name = '{column}'")
  )$data_type
  
  # nested = VARCHAR[], unnested = VARCHAR
  grepl("\\[\\]", col_type)
}
