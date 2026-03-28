
# ── Ensure macros are registered on the default connection ────────────────────
.onLoad <- function(libname, pkgname) {
  tryCatch({
    conn <- duckspatial:::ddbs_default_conn(
      bigint = "integer64"
    )
    DBI::dbExecute(conn, "INSTALL h3 FROM community; LOAD h3;")
    create_ddbh3_default_macros()
  }, error = function(e) invisible(NULL))
}