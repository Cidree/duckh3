# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Known values (checked directly in DuckDB)
h3_origin <- "87283472bffffff"
h3_cell   <- "872834729ffffff"
ij_cell   <- c(187L, 101L)
h3_res8   <- "88283470a1fffff"
h3_far    <- "8a1fb46622dffff"

## Cells within 2 steps of an origin (19 cells)
test_data <- data.frame(origin = h3_res8) |>
  ddbh3_grid_disk(k = 2, h3 = "origin", new_column = "h3string")

## Same data in other formats
test_data_df <- dplyr::collect(test_data)

test_data_sf <- ddbh3_h3_to_spatial(test_data_df, mode = "sf")

test_data_ddbs <- ddbh3_h3_to_spatial(test_data_df)

test_data_bigint <- test_data |>
  ddbh3_strings_to_bigint(h3 = "origin", new_column = "origin_bigint") |>
  ddbh3_strings_to_bigint(h3 = "h3string", new_column = "h3bigint")

## Data with known coordinates
pair_df <- data.frame(origin = h3_origin, h3string = h3_cell)
ij_df   <- data.frame(origin = h3_origin, i = ij_cell[1], j = ij_cell[2])

ddbs_collect <- duckspatial::ddbs_collect


## Helper: database arguments (name, overwrite, quiet)
check_database_args <- function(fun, x) {
  conn_test <- reset_conn_alt()
  expect_message(fun(x, conn = conn_test, name = "test_tbl"))
  expect_no_message(fun(x, conn = conn_test, name = "test_tbl2", quiet = TRUE))
  expect_error(fun(x, conn = conn_test, name = "test_tbl"))
  expect_true(fun(x, conn = conn_test, name = "test_tbl", overwrite = TRUE))
}



# 1. h3_to_local_ij() ----------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_local_ij() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_h3_to_local_ij(test_data, origin = "origin")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in(c("i", "j"), colnames(res_col))
    expect_type(res_col$i, "integer")
    expect_type(res_col$j, "integer")
    expect_equal(nrow(res_col), 19)
    expect_false(anyNA(res_col$i))
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_h3_to_local_ij(test_data_df, origin = "origin")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in(c("i", "j"), colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_h3_to_local_ij(test_data_sf, origin = "origin")
    expect_s3_class(res, "duckspatial_df")
    res_col <- ddbs_collect(res)
    expect_in(c("i", "j"), colnames(res_col))
    expect_s3_class(res_col, "sf")
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_h3_to_local_ij(test_data_ddbs, origin = "origin")
    expect_s3_class(res, "duckspatial_df")
    expect_in(c("i", "j"), colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_cells")
    res <- ddbh3_h3_to_local_ij("sf_cells", origin = "origin", conn = conn_test)
    expect_in(c("i", "j"), colnames(dplyr::collect(res)))
  })

  testthat::it("works with UBIGINT cells", {
    res_bigint <- ddbh3_h3_to_local_ij(
      test_data_bigint, origin = "origin_bigint", h3 = "h3bigint"
    ) |>
      dplyr::collect()
    res_string <- ddbh3_h3_to_local_ij(test_data_bigint, origin = "origin") |>
      dplyr::collect()
    expect_equal(res_bigint$i, res_string$i)
    expect_equal(res_bigint$j, res_string$j)
  })

  testthat::it("returns a sf object with mode = 'sf'", {
    expect_s3_class(
      ddbh3_h3_to_local_ij(test_data_sf, origin = "origin", mode = "sf"),
      "sf"
    )
  })

})


## 1.2. Values ----------

testthat::describe("ddbh3_h3_to_local_ij() returns correct values", {

  testthat::it("returns known coordinates", {
    res <- ddbh3_h3_to_local_ij(pair_df, origin = "origin") |> dplyr::collect()
    expect_equal(c(res$i, res$j), ij_cell)
  })

  testthat::it("new_column sets the names of both columns", {
    res <- ddbh3_h3_to_local_ij(pair_df, origin = "origin", new_column = c("col", "row")) |>
      dplyr::collect()
    expect_equal(colnames(res), c("origin", "h3string", "col", "row"))
    expect_equal(c(res$col, res$row), ij_cell)
  })

  testthat::it("replaces existing columns", {
    res <- data.frame(origin = h3_origin, h3string = h3_cell, i = 0L, j = "a") |>
      ddbh3_h3_to_local_ij(origin = "origin") |>
      dplyr::collect()
    expect_equal(colnames(res), c("origin", "h3string", "i", "j"))
    expect_equal(c(res$i, res$j), ij_cell)
  })

  testthat::it("replaces one existing column and appends the other", {
    res <- data.frame(origin = h3_origin, h3string = h3_cell, j = 0L) |>
      ddbh3_h3_to_local_ij(origin = "origin") |>
      dplyr::collect()
    expect_setequal(colnames(res), c("origin", "h3string", "i", "j"))
    expect_equal(c(res$i, res$j), ij_cell)
  })

  testthat::it("the origin has its own coordinates", {
    res <- ddbh3_h3_to_local_ij(test_data, origin = "origin") |>
      dplyr::collect()
    res_origin <- res[res$h3string == h3_res8, ]
    expect_equal(nrow(res_origin), 1)
    expect_true(all(abs(res$i - res_origin$i) <= 2))
    expect_true(all(abs(res$j - res_origin$j) <= 2))
  })

  testthat::it("returns NA for invalid, distant or different resolution cells", {
    res <- data.frame(
      origin   = h3_origin,
      h3string = c(h3_res8, h3_far, "zzz")
    ) |>
      ddbh3_h3_to_local_ij(origin = "origin") |>
      dplyr::collect()
    expect_true(all(is.na(res$i)))
    expect_true(all(is.na(res$j)))
  })

})


## 1.3. Errors ----------

testthat::describe("ddbh3_h3_to_local_ij() errors", {

  testthat::it("requires origin", {
    expect_error(ddbh3_h3_to_local_ij(pair_df))
  })

  testthat::it("validates character arguments", {
    expect_error(ddbh3_h3_to_local_ij(pair_df, origin = 1))
    expect_error(ddbh3_h3_to_local_ij(pair_df, origin = "origin", h3 = 1))
  })

  testthat::it("validates new_column", {
    expect_error(
      ddbh3_h3_to_local_ij(pair_df, origin = "origin", new_column = "i"),
      "2 different names"
    )
    expect_error(
      ddbh3_h3_to_local_ij(pair_df, origin = "origin", new_column = c("i", "I")),
      "2 different names"
    )
    expect_error(
      ddbh3_h3_to_local_ij(pair_df, origin = "origin", new_column = c("i", NA)),
      "2 different names"
    )
    expect_error(
      ddbh3_h3_to_local_ij(pair_df, origin = "origin", new_column = 1:2),
      "2 different names"
    )
  })

  testthat::it("validates database arguments", {
    check_database_args(
      function(x, ...) ddbh3_h3_to_local_ij(x, origin = "origin", ...),
      pair_df
    )
  })

})



# 2. local_ij_to_h3() ----------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_local_ij_to_h3() works in different formats", {

  ij_tbl <- ddbh3_h3_to_local_ij(test_data, origin = "origin")

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_local_ij_to_h3(ij_tbl, origin = "origin")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3cell", colnames(res_col))
    expect_type(res_col$h3cell, "character")
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_local_ij_to_h3(ij_df, origin = "origin")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_equal(dplyr::collect(res)$h3cell, h3_cell)
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_h3_to_local_ij(test_data_sf, origin = "origin") |>
      ddbh3_local_ij_to_h3(origin = "origin")
    expect_s3_class(res, "duckspatial_df")
    expect_s3_class(ddbs_collect(res), "sf")
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "ij_tbl", ij_df)
    res <- ddbh3_local_ij_to_h3("ij_tbl", origin = "origin", conn = conn_test)
    expect_equal(dplyr::collect(res)$h3cell, h3_cell)
  })

  testthat::it("returns UBIGINT for UBIGINT origins", {
    res <- ddbh3_h3_to_local_ij(test_data_bigint, origin = "origin_bigint", h3 = "h3bigint") |>
      ddbh3_local_ij_to_h3(origin = "origin_bigint") |>
      dplyr::collect()
    expect_s3_class(res$h3cell, "integer64")
    expect_equal(res$h3cell, res$h3bigint)
  })

})


## 2.2. Values ----------

testthat::describe("ddbh3_local_ij_to_h3() returns correct values", {

  testthat::it("round trips with ddbh3_h3_to_local_ij()", {
    res <- ddbh3_h3_to_local_ij(test_data, origin = "origin") |>
      ddbh3_local_ij_to_h3(origin = "origin") |>
      dplyr::collect()
    expect_equal(res$h3cell, res$h3string)
  })

  testthat::it("accepts other column names and doubles", {
    res <- data.frame(o = h3_origin, x = 187, y = 101) |>
      ddbh3_local_ij_to_h3(origin = "o", i = "x", j = "y", new_column = "out") |>
      dplyr::collect()
    expect_equal(res$out, h3_cell)
  })

  testthat::it("returns NA for out of range coordinates or invalid origins", {
    res <- data.frame(origin = c(h3_origin, "zzz"), i = c(100000L, 187L), j = 101L) |>
      ddbh3_local_ij_to_h3(origin = "origin") |>
      dplyr::collect()
    expect_true(all(is.na(res$h3cell)))
  })

})


## 2.3. Errors ----------

testthat::describe("ddbh3_local_ij_to_h3() errors", {

  testthat::it("requires origin", {
    expect_error(ddbh3_local_ij_to_h3(ij_df))
  })

  testthat::it("validates character arguments", {
    expect_error(ddbh3_local_ij_to_h3(ij_df, origin = 1))
    expect_error(ddbh3_local_ij_to_h3(ij_df, origin = "origin", i = 1))
    expect_error(ddbh3_local_ij_to_h3(ij_df, origin = "origin", j = c("a", "b")))
    expect_error(ddbh3_local_ij_to_h3(ij_df, origin = "origin", new_column = 1))
  })

  testthat::it("validates database arguments", {
    check_database_args(
      function(x, ...) ddbh3_local_ij_to_h3(x, origin = "origin", ...),
      ij_df
    )
  })

})



# 3. Macros --------------------------------------------------------------

testthat::describe("local IJ macros work inside mutate()", {

  testthat::it("work on lazy tables", {
    res <- ddbh3_h3_to_local_ij(test_data, origin = "origin") |>
      dplyr::mutate(
        ij      = ddbh3_h3_to_local_ij(origin, h3string),
        i_macro = ij[[1]],
        j_macro = ij[[2]],
        h3cell  = ddbh3_local_ij_to_h3(origin, i, j),
        h3next  = ddbh3_local_ij_to_h3(origin, i + 1, j)
      ) |>
      dplyr::collect()
    expect_equal(res$i_macro, res$i)
    expect_equal(res$j_macro, res$j)
    expect_equal(res$h3cell, res$h3string)
    expect_false(anyNA(res$h3next))
  })

})



# 4. Multiple new columns (build_new_column_select) ----------------------

testthat::describe("build_new_column_select() handles several columns", {

  testthat::it("appends new columns and replaces existing ones", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "cols_tbl", data.frame(a = 1L, b = 2L))
    sel <- build_new_column_select(
      conn_test, "cols_tbl", c("B", "c"), c("10", "20")
    )
    expect_equal(as.character(sel), '* REPLACE (10 AS "B"), 20 AS "c"')
    res <- DBI::dbGetQuery(conn_test, glue::glue("SELECT {sel} FROM cols_tbl"))
    expect_equal(res, data.frame(a = 1L, B = 10L, c = 20L))
  })

  testthat::it("keeps the single column behaviour", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "cols_tbl", data.frame(a = 1L))
    expect_equal(
      as.character(build_new_column_select(conn_test, "cols_tbl", "a", "2")),
      '* REPLACE (2 AS "a")'
    )
    expect_equal(
      as.character(build_new_column_select(conn_test, "cols_tbl", "z", "2", exclude = "a")),
      '* EXCLUDE ("a"), 2 AS "z"'
    )
  })

})
