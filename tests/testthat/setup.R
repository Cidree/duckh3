
# skip tests on CRAN because they take too much time
# skip_if(Sys.getenv("TEST_ONE") != "")
# testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

# Setup default connection for tests (DuckDB ignores OMP_THREAD_LIMIT)
ddbh3_default_conn(threads = 1)

# One shared secondary connection, instead of a new DuckDB instance per test
# (closed in teardown.R)
conn_alt <- ddbh3_create_conn(threads = 1)

# Drop every table and view in `conn_alt` and return it, so each test that
# needs a separate connection starts from an empty database
reset_conn_alt <- function() {
  objs <- DBI::dbGetQuery(conn_alt, "
    SELECT 'VIEW' AS type, view_name AS name FROM duckdb_views() WHERE NOT internal
    UNION ALL
    SELECT 'TABLE', table_name FROM duckdb_tables() WHERE NOT internal
  ")
  for (i in seq_len(nrow(objs))) {
    DBI::dbExecute(conn_alt, paste(
      "DROP", objs$type[i], "IF EXISTS", DBI::dbQuoteIdentifier(conn_alt, objs$name[i])
    ))
  }
  conn_alt
}
