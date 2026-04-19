
# skip tests on CRAN because they take too much time
# skip_if(Sys.getenv("TEST_ONE") != "")
# testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## Try to limit threads
Sys.setenv("OMP_THREAD_LIMIT" = 2)

# Setup default connection for tests
ddbh3_default_conn()