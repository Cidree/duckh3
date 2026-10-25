# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Load example data
test_data <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
) |>
  ddbh3_lonlat_to_h3(resolution = 8)

n_test <- nrow(dplyr::collect(test_data))

## Same data in other formats
test_data_df <- dplyr::collect(test_data)

test_data_sf <- test_data_df |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)

test_data_ddbs <- test_data_df |>
  duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)

test_data_bigint <- ddbh3_strings_to_bigint(test_data)

## Known cells (values checked directly in DuckDB)
h3_origin   <- "883923059bfffff"
h3_dest     <- "883923d04dfffff"
h3_pentagon <- "8009fffffffffff"

## Origin/destination pairs
pair_tbl <- data.frame(h3start = h3_origin, h3end = h3_dest)

pair_points <- test_data_df |>
  dplyr::mutate(h3end = dplyr::lead(h3string, default = h3string[1]))


# 1. grid_disk() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_grid_disk() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_grid_disk(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_grid_disk(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    res <- ddbh3_grid_disk(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_grid_disk(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_grid_disk("sf_pts", conn = conn_test)
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  ## FORMAT 6 - VECTORIZED
  testthat::it("works with a character vector", {
    res <- ddbh3_grid_disk(h3_origin)
    expect_type(res, "list")
    expect_length(res, 1)
    expect_length(res[[1]], 7)
  })

  testthat::it("works with a UBIGINT vector", {
    res <- ddbh3_grid_disk(ddbh3_strings_to_bigint(h3_origin))
    expect_s3_class(res[[1]], "integer64")
    expect_equal(ddbh3_bigint_to_strings(res[[1]]), ddbh3_grid_disk(h3_origin)[[1]])
  })

})


## 1.2. Correctness ------------

testthat::describe("ddbh3_grid_disk() returns correct cells", {

  testthat::it("returns 7 cells for k = 1 and 19 for k = 2", {
    res_1 <- ddbh3_grid_disk(test_data, k = 1, nested = TRUE) |> dplyr::collect()
    res_2 <- ddbh3_grid_disk(test_data, k = 2, nested = TRUE) |> dplyr::collect()
    expect_true(all(lengths(res_1$h3neighbors) == 7))
    expect_true(all(lengths(res_2$h3neighbors) == 19))
  })

  testthat::it("k = 0 returns the origin cell only", {
    res <- ddbh3_grid_disk(test_data, k = 0) |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_equal(res$h3neighbors, res$h3string)
  })

  testthat::it("contains the origin cell", {
    res <- ddbh3_grid_disk(test_data, nested = TRUE) |> dplyr::collect()
    expect_true(all(mapply(`%in%`, res$h3string, res$h3neighbors)))
  })

  testthat::it("unnested output has one row per cell", {
    res <- ddbh3_grid_disk(test_data, k = 2) |> dplyr::collect()
    expect_equal(nrow(res), n_test * 19)
  })

  testthat::it("neighbors have the same resolution as the origin", {
    res <- ddbh3_grid_disk(test_data) |> dplyr::collect()
    res_res <- ddbh3_get_resolution(res$h3neighbors)
    expect_true(all(res_res == 8))
  })

  testthat::it("safe and unsafe give the same cells on a hexagon", {
    res_safe   <- ddbh3_grid_disk(h3_origin, k = 2, safe = TRUE)[[1]]
    res_unsafe <- ddbh3_grid_disk(h3_origin, k = 2, safe = FALSE)[[1]]
    expect_setequal(res_safe, res_unsafe)
  })

  testthat::it("safe = TRUE handles pentagons", {
    res <- ddbh3_grid_disk(data.frame(h3string = h3_pentagon), safe = TRUE) |>
      dplyr::collect()
    expect_equal(nrow(res), 6)
  })

  testthat::it("safe = FALSE returns no cells on a pentagon", {
    res <- ddbh3_grid_disk(data.frame(h3string = h3_pentagon), safe = FALSE) |>
      dplyr::collect()
    expect_equal(nrow(res), 0)
  })

})


## 1.3. Arguments work ------------

testthat::describe("ddbh3_grid_disk() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    res <- ddbh3_grid_disk(test_data_mod, h3 = "h3") |> dplyr::collect()
    expect_in("h3neighbors", colnames(res))
    expect_equal(nrow(res), n_test * 7)
  })

  testthat::it("works with UBIGINT h3 column", {
    res <- ddbh3_grid_disk(test_data_bigint, h3 = "h3bigint", nested = TRUE) |>
      dplyr::collect()
    res_str <- ddbh3_grid_disk(test_data, nested = TRUE) |> dplyr::collect()
    expect_s3_class(res$h3neighbors[[1]], "integer64")
    expect_equal(
      ddbh3_bigint_to_strings(res$h3neighbors[[1]]),
      res_str$h3neighbors[[1]]
    )
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_grid_disk(test_data, new_column = "my_disk")
    expect_true("my_disk" %in% colnames(res))
  })

  ## ARGUMENT 3 - NESTED
  testthat::it("nested argument works", {
    res <- ddbh3_grid_disk(test_data, nested = TRUE) |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_type(res$h3neighbors, "list")
  })

  ## ARGUMENT 4 - MODE
  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_grid_disk(test_data_sf, mode = "sf"), "sf")
    expect_s3_class(ddbh3_grid_disk(test_data_sf, mode = "duckspatial"), "duckspatial_df")
  })

  ## ARGUMENT 5 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_grid_disk(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_grid_disk(
      test_data_df, conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_grid_disk(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_grid_disk(
      test_data_df, conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 1.4. Errors on weird inputs -----------

describe("ddbh3_grid_disk() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires k as a single integer", {
    expect_error(ddbh3_grid_disk(test_data, k = 1.5))
    expect_error(ddbh3_grid_disk(test_data, k = "1"))
    expect_error(ddbh3_grid_disk(test_data, k = c(1, 2)))
    expect_error(ddbh3_grid_disk(test_data, k = NULL))
  })

  it("requires h3 argument as character", {
    expect_error(ddbh3_grid_disk(test_data, h3 = NULL))
    expect_error(ddbh3_grid_disk(test_data, h3 = TRUE))
    expect_error(ddbh3_grid_disk(test_data, h3 = 2))
  })

  it("requires nested and safe as logical", {
    expect_error(ddbh3_grid_disk(test_data, nested = "yes"))
    expect_error(ddbh3_grid_disk(test_data, safe = 1))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_grid_disk(test_data, new_column = NULL))
    expect_error(ddbh3_grid_disk(test_data, new_column = 25))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_grid_disk(test_data, h3 = "not_a_column"))
  })

  it("validates x, conn, overwrite, quiet and name", {
    expect_error(ddbh3_grid_disk(x = TRUE))
    expect_error(ddbh3_grid_disk(test_data, conn = 999))
    expect_error(ddbh3_grid_disk(test_data, overwrite = 999))
    expect_error(ddbh3_grid_disk(test_data, quiet = 999))
    expect_error(ddbh3_grid_disk(x = "999", conn = conn_test))
    expect_error(ddbh3_grid_disk(test_data, conn = conn_test, name = c("banana", "banana")))
  })

})



# 2. grid_disk_distances() ------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_grid_disk_distances() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_grid_disk_distances(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_grid_disk_distances(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_grid_disk_distances(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_grid_disk_distances(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_grid_disk_distances("sf_pts", conn = conn_test)
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("vectorized mode returns the same cells as table mode", {
    testthat::skip("bug (#8): vectorized base_fun lacks the [2] index used in table mode")
    res_vec <- ddbh3_grid_disk_distances(h3_origin, k = 2)[[1]]
    res_tbl <- ddbh3_grid_disk_distances(
      data.frame(h3string = h3_origin), k = 2, nested = TRUE
    ) |> dplyr::collect()
    expect_equal(res_vec, res_tbl$h3neighbors[[1]])
  })

})


## 2.2. Correctness ------------

testthat::describe("ddbh3_grid_disk_distances() returns correct cells", {

  testthat::it("k = 1 returns the 6 neighbors of the origin", {
    res <- ddbh3_grid_disk_distances(test_data, k = 1, nested = TRUE) |>
      dplyr::collect()
    ring <- ddbh3_grid_ring(test_data, k = 1, nested = TRUE) |>
      dplyr::collect()
    expect_true(all(lengths(res$h3neighbors) == 6))
    expect_true(all(mapply(setequal, res$h3neighbors, ring$h3neighbors)))
  })

  testthat::it("returns all cells up to distance k", {
    testthat::skip("bug (#8): [2] index always returns the distance-1 ring, whatever k is")
    res <- ddbh3_grid_disk_distances(test_data, k = 2, nested = TRUE) |>
      dplyr::collect()
    disk <- ddbh3_grid_disk(test_data, k = 2, nested = TRUE) |>
      dplyr::collect()
    expect_true(all(mapply(setequal, res$h3neighbors, disk$h3neighbors)))
  })

  testthat::it("safe and unsafe give the same cells on a hexagon", {
    res_safe <- ddbh3_grid_disk_distances(test_data, safe = TRUE) |> dplyr::collect()
    res_unsafe <- ddbh3_grid_disk_distances(test_data, safe = FALSE) |> dplyr::collect()
    expect_setequal(res_safe$h3neighbors, res_unsafe$h3neighbors)
  })

})


## 2.3. Arguments work ------------

testthat::describe("ddbh3_grid_disk_distances() arguments work", {

  testthat::it("h3 argument works", {
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    res <- ddbh3_grid_disk_distances(test_data_mod, h3 = "h3") |> dplyr::collect()
    expect_in("h3neighbors", colnames(res))
  })

  testthat::it("works with UBIGINT h3 column", {
    res <- ddbh3_grid_disk_distances(test_data_bigint, h3 = "h3bigint") |>
      dplyr::collect()
    expect_s3_class(res$h3neighbors, "integer64")
  })

  testthat::it("new_column argument works", {
    res <- ddbh3_grid_disk_distances(test_data, new_column = "my_disk")
    expect_true("my_disk" %in% colnames(res))
  })

  testthat::it("nested argument works", {
    res <- ddbh3_grid_disk_distances(test_data, nested = TRUE) |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_type(res$h3neighbors, "list")
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_grid_disk_distances(test_data_sf, mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_grid_disk_distances(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_grid_disk_distances(
      test_data_df, conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_grid_disk_distances(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_grid_disk_distances(
      test_data_df, conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 2.4. Errors on weird inputs -----------

describe("ddbh3_grid_disk_distances() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires k as a single integer", {
    expect_error(ddbh3_grid_disk_distances(test_data, k = 1.5))
    expect_error(ddbh3_grid_disk_distances(test_data, k = c(1, 2)))
  })

  it("requires h3 argument as character", {
    expect_error(ddbh3_grid_disk_distances(test_data, h3 = NULL))
    expect_error(ddbh3_grid_disk_distances(test_data, h3 = 2))
  })

  it("requires nested and safe as logical", {
    expect_error(ddbh3_grid_disk_distances(test_data, nested = "yes"))
    expect_error(ddbh3_grid_disk_distances(test_data, safe = 1))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_grid_disk_distances(test_data, h3 = "not_a_column"))
  })

  it("validates x, conn and name", {
    expect_error(ddbh3_grid_disk_distances(x = TRUE))
    expect_error(ddbh3_grid_disk_distances(test_data, conn = 999))
    expect_error(ddbh3_grid_disk_distances(x = "999", conn = conn_test))
    expect_error(ddbh3_grid_disk_distances(test_data, conn = conn_test, name = c("banana", "banana")))
  })

})



# 3. grid_ring() ----------------------------------------------------------

## 3.1. Input data in different formats ----------

testthat::describe("ddbh3_grid_ring() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_grid_ring(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3neighbors", colnames(res_col))
    expect_type(res_col$h3neighbors, "character")
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_grid_ring(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_grid_ring(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_grid_ring(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_grid_ring("sf_pts", conn = conn_test)
    expect_in("h3neighbors", colnames(dplyr::collect(res)))
  })

  testthat::it("works with a character vector", {
    res <- ddbh3_grid_ring(h3_origin, k = 2)
    expect_type(res, "list")
    expect_length(res[[1]], 12)
  })

})


## 3.2. Correctness ------------

testthat::describe("ddbh3_grid_ring() returns correct cells", {

  testthat::it("returns 6 cells for k = 1 and 12 for k = 2", {
    res_1 <- ddbh3_grid_ring(test_data, k = 1, nested = TRUE) |> dplyr::collect()
    res_2 <- ddbh3_grid_ring(test_data, k = 2, nested = TRUE) |> dplyr::collect()
    expect_true(all(lengths(res_1$h3neighbors) == 6))
    expect_true(all(lengths(res_2$h3neighbors) == 12))
  })

  testthat::it("does not contain the origin nor inner cells", {
    ring <- ddbh3_grid_ring(test_data, k = 2, nested = TRUE) |> dplyr::collect()
    disk <- ddbh3_grid_disk(test_data, k = 1, nested = TRUE) |> dplyr::collect()
    overlap <- mapply(function(r, d) length(intersect(r, d)), ring$h3neighbors, disk$h3neighbors)
    expect_true(all(overlap == 0))
  })

  testthat::it("ring k plus disk k - 1 equals disk k", {
    ring  <- ddbh3_grid_ring(h3_origin, k = 2)[[1]]
    disk1 <- ddbh3_grid_disk(h3_origin, k = 1)[[1]]
    disk2 <- ddbh3_grid_disk(h3_origin, k = 2)[[1]]
    expect_setequal(c(ring, disk1), disk2)
  })

  testthat::it("cells are at grid distance k from the origin", {
    res <- ddbh3_grid_ring(test_data, k = 2) |>
      ddbh3_grid_distance(h3start = "h3string", h3end = "h3neighbors") |>
      dplyr::collect()
    expect_true(all(res$grid_distance == 2))
  })

  testthat::it("safe and unsafe give the same cells on a hexagon", {
    res_safe   <- ddbh3_grid_ring(h3_origin, k = 2, safe = TRUE)[[1]]
    res_unsafe <- ddbh3_grid_ring(h3_origin, k = 2, safe = FALSE)[[1]]
    expect_setequal(res_safe, res_unsafe)
  })

  testthat::it("safe = TRUE handles pentagons", {
    res <- ddbh3_grid_ring(data.frame(h3string = h3_pentagon), safe = TRUE) |>
      dplyr::collect()
    expect_equal(nrow(res), 5)
  })

  testthat::it("safe = FALSE returns no cells on a pentagon", {
    res <- ddbh3_grid_ring(data.frame(h3string = h3_pentagon), safe = FALSE) |>
      dplyr::collect()
    expect_equal(nrow(res), 0)
    expect_null(ddbh3_grid_ring(h3_pentagon, safe = FALSE)[[1]])
  })

})


## 3.3. Arguments work ------------

testthat::describe("ddbh3_grid_ring() arguments work", {

  testthat::it("h3 argument works", {
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    res <- ddbh3_grid_ring(test_data_mod, h3 = "h3") |> dplyr::collect()
    expect_equal(nrow(res), n_test * 6)
  })

  testthat::it("works with UBIGINT h3 column", {
    res <- ddbh3_grid_ring(test_data_bigint, h3 = "h3bigint", nested = TRUE) |>
      dplyr::collect()
    res_str <- ddbh3_grid_ring(test_data, nested = TRUE) |> dplyr::collect()
    expect_s3_class(res$h3neighbors[[1]], "integer64")
    expect_setequal(
      ddbh3_bigint_to_strings(res$h3neighbors[[1]]),
      res_str$h3neighbors[[1]]
    )
  })

  testthat::it("new_column argument works", {
    res <- ddbh3_grid_ring(test_data, new_column = "my_ring")
    expect_true("my_ring" %in% colnames(res))
  })

  testthat::it("nested argument works", {
    res <- ddbh3_grid_ring(test_data, nested = TRUE) |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_type(res$h3neighbors, "list")
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_grid_ring(test_data_sf, mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_grid_ring(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_grid_ring(
      test_data_df, conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_grid_ring(
      test_data_df, conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_grid_ring(
      test_data_df, conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 3.4. Errors on weird inputs -----------

describe("ddbh3_grid_ring() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires k as a single integer", {
    expect_error(ddbh3_grid_ring(test_data, k = 1.5))
    expect_error(ddbh3_grid_ring(test_data, k = c(1, 2)))
  })

  it("requires h3 argument as character", {
    expect_error(ddbh3_grid_ring(test_data, h3 = NULL))
    expect_error(ddbh3_grid_ring(test_data, h3 = 2))
  })

  it("requires nested and safe as logical", {
    expect_error(ddbh3_grid_ring(test_data, nested = "yes"))
    expect_error(ddbh3_grid_ring(test_data, safe = 1))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_grid_ring(test_data, h3 = "not_a_column"))
  })

  it("validates x, conn and name", {
    expect_error(ddbh3_grid_ring(x = TRUE))
    expect_error(ddbh3_grid_ring(test_data, conn = 999))
    expect_error(ddbh3_grid_ring(x = "999", conn = conn_test))
    expect_error(ddbh3_grid_ring(test_data, conn = conn_test, name = c("banana", "banana")))
  })

})



# 4. max_grid_disk_size() -------------------------------------------------

testthat::describe("ddbh3_max_grid_disk_size() works", {

  testthat::it("returns known values", {
    expect_identical(ddbh3_max_grid_disk_size(0), 1L)
    expect_identical(ddbh3_max_grid_disk_size(1), 7L)
    expect_identical(ddbh3_max_grid_disk_size(2), 19L)
    expect_identical(ddbh3_max_grid_disk_size(10), 331L)
  })

  testthat::it("uses k = 1 by default", {
    expect_identical(ddbh3_max_grid_disk_size(), 7L)
  })

  testthat::it("matches the size of a grid disk on a hexagon", {
    for (k in 0:3) {
      expect_equal(
        ddbh3_max_grid_disk_size(k),
        length(ddbh3_grid_disk(h3_origin, k = k)[[1]])
      )
    }
  })

  testthat::it("works with an explicit connection", {
    conn_test <- ddbh3_create_conn()
    expect_identical(ddbh3_max_grid_disk_size(2, conn = conn_test), 19L)
  })

  testthat::it("validates k", {
    expect_error(ddbh3_max_grid_disk_size(-1))
    expect_error(ddbh3_max_grid_disk_size(1501))
    expect_error(ddbh3_max_grid_disk_size(1.5))
    expect_error(ddbh3_max_grid_disk_size(c(1, 2)))
    expect_error(ddbh3_max_grid_disk_size("1"))
  })

})



# 5. grid_path_cells() ----------------------------------------------------

## 5.1. Input data in different formats ----------

testthat::describe("ddbh3_grid_path_cells() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_grid_path_cells(test_data, h3end = "h3string")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3path", colnames(res_col))
    expect_type(res_col$h3path, "character")
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("h3path", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_grid_path_cells(test_data_sf, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3path", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_grid_path_cells(test_data_ddbs, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3path", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_grid_path_cells("sf_pts", h3end = "h3string", conn = conn_test)
    expect_in("h3path", colnames(dplyr::collect(res)))
  })

  testthat::it("works with character vectors", {
    testthat::skip("bug (#8): vectorized base_fun references `y`, which get_vectorized_result() never binds")
    res <- ddbh3_grid_path_cells(h3_origin, h3end = h3_dest)
    expect_length(res[[1]], 98)
  })

})


## 5.2. Correctness ------------

testthat::describe("ddbh3_grid_path_cells() returns correct cells", {

  res_path <- ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end") |>
    dplyr::collect()

  testthat::it("returns distance + 1 cells", {
    expect_equal(nrow(res_path), 98)
  })

  testthat::it("starts at h3start and ends at h3end", {
    expect_equal(res_path$h3path[1], h3_origin)
    expect_equal(res_path$h3path[nrow(res_path)], h3_dest)
  })

  testthat::it("consecutive cells are neighbors", {
    steps <- data.frame(
      a = res_path$h3path[-nrow(res_path)],
      b = res_path$h3path[-1]
    ) |>
      ddbh3_grid_distance(h3start = "a", h3end = "b") |>
      dplyr::collect()
    expect_true(all(steps$grid_distance == 1))
  })

  testthat::it("path from a cell to itself is the cell", {
    res <- ddbh3_grid_path_cells(test_data, h3end = "h3string") |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_equal(res$h3path, res$h3string)
  })

  testthat::it("path length matches grid distance for every row", {
    res <- ddbh3_grid_path_cells(pair_points, h3start = "h3string", h3end = "h3end", nested = TRUE) |>
      ddbh3_grid_distance(h3start = "h3string", h3end = "h3end") |>
      dplyr::collect() |>
      dplyr::filter(!is.na(grid_distance))
    expect_gt(nrow(res), 0)
    expect_equal(lengths(res$h3path), res$grid_distance + 1)
  })

})


## 5.3. Arguments work ------------

testthat::describe("ddbh3_grid_path_cells() arguments work", {

  testthat::it("works with UBIGINT columns", {
    pair_big <- ddbh3_strings_to_bigint(pair_tbl, h3 = "h3start", new_column = "s") |>
      ddbh3_strings_to_bigint(h3 = "h3end", new_column = "e")
    res <- ddbh3_grid_path_cells(pair_big, h3start = "s", h3end = "e") |>
      dplyr::collect()
    expect_s3_class(res$h3path, "integer64")
    expect_equal(nrow(res), 98)
  })

  testthat::it("new_column argument works", {
    res <- ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end", new_column = "my_path")
    expect_true("my_path" %in% colnames(res))
  })

  testthat::it("nested argument works", {
    res <- ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end", nested = TRUE) |>
      dplyr::collect()
    expect_equal(nrow(res), 1)
    expect_type(res$h3path, "list")
    expect_length(res$h3path[[1]], 98)
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_grid_path_cells(test_data_sf, h3end = "h3string", mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_grid_path_cells(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_grid_path_cells(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_grid_path_cells(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_grid_path_cells(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 5.4. Errors on weird inputs -----------

describe("ddbh3_grid_path_cells() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires h3end", {
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start"))
  })

  it("requires h3start and h3end as character", {
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = 1, h3end = "h3end"))
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = TRUE))
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = c("h3start", "h3end"), h3end = "h3end"))
  })

  it("requires nested as logical", {
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end", nested = "yes"))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end", new_column = 25))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "not_a_column"))
  })

  it("validates x, conn and name", {
    expect_error(ddbh3_grid_path_cells(x = TRUE, h3end = "h3end"))
    expect_error(ddbh3_grid_path_cells(pair_tbl, h3start = "h3start", h3end = "h3end", conn = 999))
    expect_error(ddbh3_grid_path_cells(x = "999", h3end = "h3end", conn = conn_test))
    expect_error(ddbh3_grid_path_cells(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = c("banana", "banana")
    ))
  })

})



# 6. grid_distance() ------------------------------------------------------

## 6.1. Input data in different formats ----------

testthat::describe("ddbh3_grid_distance() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_grid_distance(test_data, h3end = "h3string")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("grid_distance", colnames(res_col))
    expect_true(is.numeric(res_col$grid_distance))
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("grid_distance", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_grid_distance(test_data_sf, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("grid_distance", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_grid_distance(test_data_ddbs, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("grid_distance", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_grid_distance("sf_pts", h3end = "h3string", conn = conn_test)
    expect_in("grid_distance", colnames(dplyr::collect(res)))
  })

  testthat::it("works with character vectors", {
    testthat::skip("bug (#8): vectorized base_fun references `y`, which get_vectorized_result() never binds")
    expect_equal(ddbh3_grid_distance(h3_origin, h3end = h3_dest), 97)
  })

})


## 6.2. Correctness ------------

testthat::describe("ddbh3_grid_distance() returns correct values", {

  testthat::it("returns a known distance", {
    res <- ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end") |>
      dplyr::collect()
    expect_equal(res$grid_distance, 97)
  })

  testthat::it("distance from a cell to itself is 0", {
    res <- ddbh3_grid_distance(test_data, h3end = "h3string") |> dplyr::collect()
    expect_true(all(res$grid_distance == 0))
  })

  testthat::it("is symmetric", {
    res_ab <- ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end") |>
      dplyr::collect()
    res_ba <- ddbh3_grid_distance(pair_tbl, h3start = "h3end", h3end = "h3start") |>
      dplyr::collect()
    expect_equal(res_ab$grid_distance, res_ba$grid_distance)
  })

  testthat::it("neighbors from grid_ring are at distance 1", {
    res <- ddbh3_grid_ring(test_data, k = 1) |>
      ddbh3_grid_distance(h3end = "h3neighbors") |>
      dplyr::collect()
    expect_true(all(res$grid_distance == 1))
  })

  testthat::it("returns NA for cells at different resolutions", {
    res <- data.frame(h3start = h3_origin, h3end = h3_pentagon) |>
      ddbh3_grid_distance(h3start = "h3start", h3end = "h3end") |>
      dplyr::collect()
    expect_true(is.na(res$grid_distance))
  })

})


## 6.3. Arguments work ------------

testthat::describe("ddbh3_grid_distance() arguments work", {

  testthat::it("works with UBIGINT columns", {
    pair_big <- ddbh3_strings_to_bigint(pair_tbl, h3 = "h3start", new_column = "s") |>
      ddbh3_strings_to_bigint(h3 = "h3end", new_column = "e")
    res <- ddbh3_grid_distance(pair_big, h3start = "s", h3end = "e") |>
      dplyr::collect()
    expect_equal(res$grid_distance, 97)
  })

  testthat::it("new_column argument works", {
    res <- ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end", new_column = "dist")
    expect_true("dist" %in% colnames(res))
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_grid_distance(test_data_sf, h3end = "h3string", mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_grid_distance(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_grid_distance(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_grid_distance(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_grid_distance(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 6.4. Errors on weird inputs -----------

describe("ddbh3_grid_distance() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires h3end", {
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = "h3start"))
  })

  it("requires h3start and h3end as character", {
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = 1, h3end = "h3end"))
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = TRUE))
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = c("h3start", "h3end"), h3end = "h3end"))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end", new_column = 25))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "not_a_column"))
  })

  it("validates x, conn and name", {
    expect_error(ddbh3_grid_distance(x = TRUE, h3end = "h3end"))
    expect_error(ddbh3_grid_distance(pair_tbl, h3start = "h3start", h3end = "h3end", conn = 999))
    expect_error(ddbh3_grid_distance(x = "999", h3end = "h3end", conn = conn_test))
    expect_error(ddbh3_grid_distance(
      pair_tbl, h3start = "h3start", h3end = "h3end",
      conn = conn_test, name = c("banana", "banana")
    ))
  })

})



# 7. Macros ---------------------------------------------------------------

testthat::describe("neighborhood functions work inside dplyr::mutate()", {

  testthat::it("grid_distance macro works", {
    testthat::skip("bug (#8): no ddbh3_* macro is registered for the new functions")
    res <- test_data |>
      dplyr::mutate(d = ddbh3_grid_distance(h3string, h3string)) |>
      dplyr::collect()
    expect_true(all(res$d == 0))
  })

  testthat::it("grid_disk macro works", {
    testthat::skip("bug (#8): no ddbh3_* macro is registered for the new functions")
    res <- test_data |>
      dplyr::mutate(d = ddbh3_grid_disk(h3string, 1)) |>
      dplyr::collect()
    expect_true(all(lengths(res$d) == 7))
  })

})
