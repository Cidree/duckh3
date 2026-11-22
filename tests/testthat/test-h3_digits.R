# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Known values (decoded from the bits of the indexes)
h3_cell   <- "88283470a1fffff"
h3_res3   <- "832834fffffffff"
h3_res0   <- "8001fffffffffff"

test_data_df <- data.frame(base_cell = c(20, 20, 0))
test_data_df$digits <- list(c(0, 6, 4, 3, 4, 1, 2, 0), c(0, 6, 4), numeric(0))
expected <- c(h3_cell, h3_res3, h3_res0)

test_data <- dplyr::copy_to(conn_test, test_data_df, overwrite = TRUE)

test_data_sf <- data.frame(lon = c(-3.7, 2.17, 0), lat = c(40.4, 41.4, 0)) |>
  cbind(test_data_df) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

ddbs_collect <- duckspatial::ddbs_collect


## Helper: database arguments (name, overwrite, quiet)
check_database_args <- function(fun, x) {
  conn_test <- reset_conn_alt()
  expect_message(fun(x, conn = conn_test, name = "test_tbl"))
  expect_no_message(fun(x, conn = conn_test, name = "test_tbl2", quiet = TRUE))
  expect_error(fun(x, conn = conn_test, name = "test_tbl"))
  expect_true(fun(x, conn = conn_test, name = "test_tbl", overwrite = TRUE))
}



# 1. digits_to_h3() ------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_digits_to_h3() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_digits_to_h3(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_equal(dplyr::collect(res)$h3string, expected)
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_digits_to_h3(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_equal(dplyr::collect(res)$h3string, expected)
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_digits_to_h3(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    res_col <- ddbs_collect(res)
    expect_s3_class(res_col, "sf")
    expect_equal(res_col$h3string, expected)
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbExecute(conn_test, "
      CREATE TABLE digits_tbl AS
      SELECT 20 AS base_cell, [0, 6, 4, 3, 4, 1, 2, 0] AS digits
    ")
    res <- ddbh3_digits_to_h3("digits_tbl", conn = conn_test)
    expect_equal(dplyr::collect(res)$h3string, h3_cell)
  })

  testthat::it("returns a sf object with mode = 'sf'", {
    expect_s3_class(ddbh3_digits_to_h3(test_data_sf, mode = "sf"), "sf")
  })

})


## 1.2. Values ----------

testthat::describe("ddbh3_digits_to_h3() returns correct values", {

  testthat::it("h3_format = 'bigint' returns UBIGINT", {
    res <- ddbh3_digits_to_h3(test_data, h3_format = "bigint") |>
      dplyr::collect()
    expect_s3_class(res$h3string, "integer64")
    expect_equal(
      res$h3string,
      ddbh3_strings_to_bigint(data.frame(h3string = expected)) |>
        dplyr::collect() |>
        dplyr::pull(h3bigint)
    )
  })

  testthat::it("the resolution is the number of digits", {
    res <- ddbh3_digits_to_h3(test_data) |>
      ddbh3_get_resolution() |>
      dplyr::collect()
    expect_equal(res$h3resolution, c(8L, 3L, 0L))
  })

  testthat::it("works with other column names and integer digits", {
    df <- data.frame(bc = 20L)
    df$d <- list(c(0L, 6L, 4L))
    res <- ddbh3_digits_to_h3(df, base_cell = "bc", digits = "d", new_column = "out") |>
      dplyr::collect()
    expect_equal(res$out, h3_res3)
  })

  testthat::it("replaces an existing column", {
    df <- test_data_df
    df$h3string <- "a"
    res <- ddbh3_digits_to_h3(df) |> dplyr::collect()
    expect_equal(colnames(res), c("base_cell", "digits", "h3string"))
    expect_equal(res$h3string, expected)
  })

  testthat::it("returns NA for invalid base cells or digits", {
    df <- data.frame(base_cell = c(200, 20, 20))
    df$digits <- list(c(0, 1), c(9, 0), c(0, 6, 4))
    res <- ddbh3_digits_to_h3(df) |> dplyr::collect()
    expect_equal(res$h3string, c(NA, NA, h3_res3))
  })

})


## 1.3. Macros ----------

testthat::describe("ddbh3_digits_to_h3() works inside mutate()", {

  testthat::it("returns H3 strings", {
    res <- test_data |>
      dplyr::mutate(h3 = ddbh3_digits_to_h3(base_cell, digits)) |>
      dplyr::collect()
    expect_equal(res$h3, expected)
  })

})


## 1.4. Errors ----------

testthat::describe("ddbh3_digits_to_h3() errors", {

  testthat::it("validates character arguments", {
    expect_error(ddbh3_digits_to_h3(test_data, base_cell = 1))
    expect_error(ddbh3_digits_to_h3(test_data, digits = 1))
    expect_error(ddbh3_digits_to_h3(test_data, new_column = 1))
  })

  testthat::it("validates h3_format", {
    expect_error(ddbh3_digits_to_h3(test_data, h3_format = "int"), "h3_format")
    expect_error(ddbh3_digits_to_h3(test_data, h3_format = c("string", "bigint")))
  })

  testthat::it("errors when the columns do not exist", {
    expect_error(dplyr::collect(ddbh3_digits_to_h3(test_data, base_cell = "zzz")))
  })

  testthat::it("validates x, conn, overwrite and quiet", {
    expect_error(ddbh3_digits_to_h3(x = 999))
    expect_error(ddbh3_digits_to_h3(test_data, conn = 999))
    expect_error(ddbh3_digits_to_h3(test_data, overwrite = 999))
    expect_error(ddbh3_digits_to_h3(test_data, quiet = 999))
  })

  testthat::it("validates database arguments", {
    check_database_args(ddbh3_digits_to_h3, test_data_df)
  })

})
