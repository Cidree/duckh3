

# create_duckdbh3_macros <- function(conn) {
#   DBI::dbExecute(
#     conn,
#     "CREATE OR REPLACE MACRO ddbh3_lonlat_to_strings(lon, lat, level) AS h3_latlng_to_cell_string(lat, lon, CAST(level AS INTEGER));
#     "
#   )
# }
