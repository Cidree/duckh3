
# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)


# 1. ddbh3_create_conn() -----------------------------------------------------

testthat::describe("ddbh3_create_conn()", {

  testthat::it("registers the ddbh3 macros, so they work inside mutate()", {
    conn <- ddbh3_create_conn(threads = 1)
    on.exit(duckspatial::ddbs_stop_conn(conn), add = TRUE)

    ## Use the connection without passing through any ddbh3_* function first
    duckdb::dbWriteTable(conn, "cells", data.frame(h3 = "8928308280fffff"))
    res <- dplyr::tbl(conn, "cells") |>
      dplyr::mutate(res = ddbh3_get_resolution(h3)) |>
      dplyr::collect()

    expect_equal(res$res, 9)
  })

})


# 2. ddbh3_default_conn() ----------------------------------------------------

testthat::describe("ddbh3_default_conn()", {

  testthat::it("returns the existing connection when called again", {
    expect_identical(ddbh3_default_conn(), conn_test)
  })

  testthat::it("returns NULL without error when create = FALSE and no connection exists", {
    old <- options(duckspatial_conn = NULL)
    on.exit(options(old), add = TRUE)
    expect_null(ddbh3_default_conn(create = FALSE))
  })

})


# 3. check_installed_h3() ----------------------------------------------------

testthat::describe("check_installed_h3()", {

  testthat::it("passes on the default connection and on a new h3 connection", {
    expect_true(check_installed_h3(conn_test))
    conn <- ddbh3_create_conn(threads = 1)
    on.exit(duckspatial::ddbs_stop_conn(conn), add = TRUE)
    expect_true(check_installed_h3(conn))
  })

  testthat::it("errors on a connection without h3 loaded", {
    conn <- duckspatial::ddbs_create_conn(threads = 1)
    on.exit(duckspatial::ddbs_stop_conn(conn), add = TRUE)
    expect_error(check_installed_h3(conn), "h3")
  })

})
