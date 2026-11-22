# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Known values: two complete res-7 cells and one extra res-8 cell
h3_parent_a <- "87283472bffffff"
h3_parent_b <- "872834729ffffff"
h3_extra    <- "88283470a1fffff"

## All the res-8 children of the parents, plus the extra cell (15 rows)
cells_df <- data.frame(
  region   = c("A", "B", "B"),
  h3string = c(h3_parent_a, h3_parent_b, h3_extra)
) |>
  ddbh3_get_children(resolution = 8, new_column = "h3children") |>
  dplyr::collect()

cells_tbl <- ddbh3_get_children(
  data.frame(region = c("A", "B", "B"), h3string = c(h3_parent_a, h3_parent_b, h3_extra)),
  resolution = 8, new_column = "h3children"
)

cells_sf <- ddbh3_h3_to_spatial(cells_df, h3 = "h3children", mode = "sf")

cells_bigint <- ddbh3_strings_to_bigint(cells_tbl, h3 = "h3children")

## Compacted cells per region
compact_df <- data.frame(
  region    = c("A", "B", "B"),
  h3compact = c(h3_parent_a, h3_parent_b, h3_extra)
)


## Helper: database arguments (name, overwrite, quiet)
check_database_args <- function(fun, x, ...) {
  conn_test <- reset_conn_alt()
  expect_message(fun(x, ..., conn = conn_test, name = "test_tbl"))
  expect_no_message(fun(x, ..., conn = conn_test, name = "test_tbl2", quiet = TRUE))
  expect_error(fun(x, ..., conn = conn_test, name = "test_tbl"))
  expect_true(fun(x, ..., conn = conn_test, name = "test_tbl", overwrite = TRUE))
}

sorted <- function(x) sort(as.character(x))



# 1. compact() -----------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_compact() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_equal(colnames(res_col), "h3compact")
    expect_equal(sorted(res_col$h3compact), sorted(compact_df$h3compact))
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_compact(cells_df, h3 = "h3children") |> dplyr::collect()
    expect_equal(sorted(res$h3compact), sorted(compact_df$h3compact))
  })

  testthat::it("returns a non-spatial table for sf", {
    res <- ddbh3_compact(cells_sf, h3 = "h3children", by = "region")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_false(inherits(res, "duckspatial_df"))
    expect_equal(colnames(dplyr::collect(res)), c("region", "h3compact"))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "cells", cells_df)
    res <- ddbh3_compact("cells", h3 = "h3children", conn = conn_test) |>
      dplyr::collect()
    expect_equal(sorted(res$h3compact), sorted(compact_df$h3compact))
  })

  testthat::it("works with UBIGINT cells", {
    res <- ddbh3_compact(cells_bigint, h3 = "h3bigint") |>
      ddbh3_bigint_to_strings(h3 = "h3compact") |>
      dplyr::collect()
    expect_true(bit64::is.integer64(res$h3compact))
    expect_equal(sorted(res$h3string), sorted(compact_df$h3compact))
  })

})


## 1.2. Arguments ----------

testthat::describe("ddbh3_compact() arguments work", {

  testthat::it("by groups the cells", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region") |>
      dplyr::collect() |>
      dplyr::arrange(region, h3compact)
    exp <- dplyr::arrange(compact_df, region, h3compact)
    expect_equal(res$region, exp$region)
    expect_equal(res$h3compact, exp$h3compact)
  })

  testthat::it("by accepts several columns", {
    res <- cells_df |>
      dplyr::mutate(country = "X") |>
      ddbh3_compact(h3 = "h3children", by = c("country", "region")) |>
      dplyr::collect()
    expect_equal(colnames(res), c("country", "region", "h3compact"))
    expect_equal(nrow(res), 3)
  })

  testthat::it("nested returns one row per group", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region", nested = TRUE) |>
      dplyr::collect() |>
      dplyr::arrange(region)
    expect_equal(nrow(res), 2)
    expect_type(res$h3compact, "list")
    expect_equal(lengths(res$h3compact), c(1, 2))
  })

  testthat::it("nested without by returns one row", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", nested = TRUE) |>
      dplyr::collect()
    expect_equal(nrow(res), 1)
    expect_length(res$h3compact[[1]], 3)
  })

  testthat::it("accepts a list column of cells", {
    nested_tbl <- ddbh3_get_children(
      data.frame(h3string = c(h3_parent_a, h3_parent_b)), resolution = 8, nested = TRUE
    )
    res <- ddbh3_compact(nested_tbl, h3 = "h3children") |> dplyr::collect()
    expect_equal(sorted(res$h3compact), sorted(c(h3_parent_a, h3_parent_b)))
  })

  testthat::it("ignores duplicated cells", {
    res <- dplyr::bind_rows(cells_df, cells_df) |>
      ddbh3_compact(h3 = "h3children") |>
      dplyr::collect()
    expect_equal(sorted(res$h3compact), sorted(compact_df$h3compact))
  })

  testthat::it("compacts recursively across resolutions", {
    res <- ddbh3_get_children(h3_parent_a, resolution = 9)[[1]] |>
      ddbh3_compact()
    expect_equal(res, h3_parent_a)
  })

  testthat::it("new_column works", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", new_column = "cells") |>
      dplyr::collect()
    expect_equal(colnames(res), "cells")
  })

  testthat::it("works inside summarise", {
    res <- cells_tbl |>
      dplyr::summarise(h3compact = ddbh3_compact(h3children), .by = region) |>
      dplyr::collect() |>
      dplyr::arrange(region)
    expect_equal(lengths(res$h3compact), c(1, 2))
  })

  testthat::it("works in vectorized mode", {
    res <- ddbh3_compact(cells_df$h3children)
    expect_type(res, "character")
    expect_equal(sorted(res), sorted(compact_df$h3compact))
  })

  testthat::it("drops groups with invalid cells", {
    bad_df <- data.frame(region = c("A", "B"), h3string = c(h3_extra, "zzz"))
    res <- ddbh3_compact(bad_df, by = "region") |> dplyr::collect()
    expect_equal(res$region, "A")
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_compact, cells_df, h3 = "h3children")
  })

})


## 1.3. Errors ----------

describe("ddbh3_compact() errors", {

  it("requires h3 argument as character", {
    expect_error(ddbh3_compact(cells_tbl, h3 = 25))
    expect_error(ddbh3_compact(cells_tbl, h3 = c("h3string", "h3children")))
  })

  it("validates by", {
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", by = 1), "by")
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", by = NA_character_), "by")
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", by = "not_a_column"))
  })

  it("validates nested", {
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", nested = "yes"))
  })

  it("rejects invalid cells in vectorized mode", {
    expect_error(ddbh3_compact(c(h3_extra, "zzz")), "invalid")
  })

  it("validates x, conn and name", {
    conn_test <- reset_conn_alt()
    expect_error(ddbh3_compact(x = TRUE))
    expect_error(ddbh3_compact(cells_tbl, conn = 999))
    expect_error(ddbh3_compact(x = "999", conn = conn_test))
  })

  it("validates overwrite and quiet", {
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", overwrite = 1))
    expect_error(ddbh3_compact(cells_tbl, h3 = "h3children", quiet = 1))
  })

})



# 2. uncompact() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_uncompact() works in different formats", {

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = 8)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_equal(colnames(res_col), c("region", "h3compact", "h3uncompact"))
    expect_equal(sorted(res_col$h3uncompact), sorted(cells_df$h3children))
  })

  testthat::it("returns the correct data for sf", {
    compact_sf <- ddbh3_h3_to_spatial(compact_df, h3 = "h3compact", mode = "sf")
    res <- ddbh3_uncompact(compact_sf, h3 = "h3compact", resolution = 8)
    expect_s3_class(res, "duckspatial_df")
    expect_equal(nrow(dplyr::collect(res)), 15)
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "compact", compact_df)
    res <- ddbh3_uncompact("compact", h3 = "h3compact", resolution = 8, conn = conn_test) |>
      dplyr::collect()
    expect_equal(nrow(res), 15)
  })

  testthat::it("works with UBIGINT cells", {
    res <- ddbh3_strings_to_bigint(compact_df, h3 = "h3compact") |>
      ddbh3_uncompact(h3 = "h3bigint", resolution = 8) |>
      dplyr::collect()
    expect_true(bit64::is.integer64(res$h3uncompact))
    expect_equal(nrow(res), 15)
  })

})


## 2.2. Arguments ----------

testthat::describe("ddbh3_uncompact() arguments work", {

  testthat::it("nested returns one list per row", {
    res <- ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = 8, nested = TRUE) |>
      dplyr::collect()
    expect_equal(nrow(res), 3)
    expect_equal(lengths(res$h3uncompact), c(7, 7, 1))
  })

  testthat::it("accepts a list column of cells", {
    nested_tbl <- ddbh3_compact(compact_df, h3 = "h3compact", by = "region", nested = TRUE)
    res <- ddbh3_uncompact(nested_tbl, h3 = "h3compact", resolution = 8, nested = TRUE) |>
      dplyr::collect() |>
      dplyr::arrange(region)
    expect_equal(lengths(res$h3uncompact), c(7, 8))
  })

  testthat::it("accepts a list column in a table name", {
    conn_test <- reset_conn_alt()
    DBI::dbExecute(conn_test, glue::glue("CREATE TABLE lst AS SELECT ['{h3_parent_a}'] AS cells"))
    res <- ddbh3_uncompact("lst", h3 = "cells", resolution = 8, conn = conn_test) |>
      dplyr::collect()
    expect_equal(nrow(res), 7)
  })

  testthat::it("roundtrips with compact", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region") |>
      ddbh3_uncompact(h3 = "h3compact", resolution = 8) |>
      dplyr::collect()
    expect_equal(sorted(res$h3uncompact), sorted(cells_df$h3children))
  })

  testthat::it("handles cells finer than resolution", {
    fine_df <- data.frame(h3string = h3_extra)
    res_nested <- ddbh3_uncompact(fine_df, resolution = 7, nested = TRUE) |>
      dplyr::collect()
    expect_null(res_nested$h3uncompact[[1]])
    res <- ddbh3_uncompact(fine_df, resolution = 7) |> dplyr::collect()
    expect_equal(nrow(res), 0)
  })

  testthat::it("works inside mutate on a list column", {
    res <- ddbh3_compact(cells_tbl, h3 = "h3children", by = "region", nested = TRUE) |>
      dplyr::mutate(cells = ddbh3_uncompact(h3compact, 8)) |>
      dplyr::collect() |>
      dplyr::arrange(region)
    expect_equal(lengths(res$cells), c(7, 8))
  })

  testthat::it("works in vectorized mode", {
    res <- ddbh3_uncompact(compact_df$h3compact, resolution = 8)
    expect_type(res, "character")
    expect_equal(sorted(res), sorted(cells_df$h3children))
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_uncompact, compact_df, h3 = "h3compact")
  })

})


## 2.3. Errors ----------

describe("ddbh3_uncompact() errors", {

  it("requires h3 argument as character", {
    expect_error(ddbh3_uncompact(compact_df, h3 = 25))
    expect_error(ddbh3_uncompact(compact_df, h3 = "not_a_column"))
  })

  it("validates resolution", {
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = 16))
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = -1))
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = "8"))
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", resolution = c(8, 9)))
  })

  it("validates nested", {
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", nested = "yes"))
  })

  it("rejects invalid cells in vectorized mode", {
    expect_error(ddbh3_uncompact(c(h3_extra, "zzz"), resolution = 8), "invalid")
  })

  it("validates overwrite and quiet", {
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", overwrite = 1))
    expect_error(ddbh3_uncompact(compact_df, h3 = "h3compact", quiet = 1))
  })

})
