

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
  ddbh3_lonlat_to_h3(resolution = 10)

test_data_5 <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
) |> 
  head(1) |> 
  ddbh3_lonlat_to_h3(resolution = 5)

# 1. get_parent() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_get_parent() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_parent(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_parent(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_parent(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_parent(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_parent("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

})


testthat::test_that("parent has lower resolution than child", {
  res <- ddbh3_get_parent(test_data, resolution = 5) |>
    dplyr::collect()
  ## Get resolution of parent cells
  parent_res <- ddbh3_get_resolution(
    data.frame(h3string = res$h3parent)
  ) |>
    dplyr::collect()
  expect_true(all(parent_res$h3resolution == 5))
})

testthat::test_that("lower resolution returns coarser parent", {
  res_coarse <- ddbh3_get_parent(test_data, resolution = 3) |>
    dplyr::collect()
  res_fine <- ddbh3_get_parent(test_data, resolution = 6) |>
    dplyr::collect()
  ## Coarser parent strings should differ from finer parent strings
  expect_false(identical(res_coarse$h3parent, res_fine$h3parent))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_get_parent() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_parent(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3parent", colnames(res_col))
    expect_type(res_col$h3parent, "character")
  })

  ## ARGUMENT 2 - RESOLUTION
  testthat::it("resolution argument works", {
    ## All valid resolutions return results
    for (r in c(0, 3, 7, 15)) {
      res <- ddbh3_get_parent(test_data, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3parent, "character")
    }
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_parent(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_parent(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_parent(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_parent(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_parent(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 1.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_parent(test_data, h3 = NULL))
    expect_error(ddbh3_get_parent(test_data, h3 = TRUE))
    expect_error(ddbh3_get_parent(test_data, h3 = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_get_parent(test_data, resolution = NULL))
    expect_error(ddbh3_get_parent(test_data, resolution = "a"))
    expect_error(ddbh3_get_parent(test_data, resolution = 1.5))
    expect_error(ddbh3_get_parent(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_get_parent(test_data, resolution = -1))
    expect_error(ddbh3_get_parent(test_data, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_parent(test_data, new_column = NULL))
    expect_error(ddbh3_get_parent(test_data, new_column = FALSE))
    expect_error(ddbh3_get_parent(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_error(
      ddbh3_get_parent("test_data_tbl", conn = NULL),
      "If `x` is a table, `conn` cannot be NULL"
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_parent(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_parent(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_parent(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_parent(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_parent(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_parent(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 2. get_children() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_get_children() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_children(test_data_5)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_5_df <- dplyr::collect(test_data_5)
    res <- ddbh3_get_children(test_data_5_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_5_sf <- test_data_5 |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_children(test_data_5_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_5_ddbs <- test_data_5 |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_children(test_data_5_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_5_sf <- test_data_5 |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_5_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_children("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

})


testthat::test_that("unnested result has more rows than nested", {
  ## Unnested (default): one row per child
  res_unnested <- ddbh3_get_children(test_data_5, nested = FALSE) |>
    dplyr::collect()
  ## Nested: one row per parent cell, children column contains a list
  res_nested <- ddbh3_get_children(test_data_5, nested = TRUE) |>
    dplyr::collect()
  expect_gt(nrow(res_unnested), nrow(res_nested))
})

testthat::test_that("nested result has same number of rows as input", {
  res_nested <- ddbh3_get_children(test_data_5, nested = TRUE) |>
    dplyr::collect()
  expect_equal(nrow(res_nested), nrow(dplyr::collect(test_data_5)))
})

testthat::test_that("children have higher resolution than parent", {
  res <- ddbh3_get_children(test_data_5, resolution = 6, nested = FALSE) |>
    dplyr::collect()
  ## Get resolution of children cells
  children_res <- ddbh3_get_resolution(
    data.frame(h3string = res$h3children)
  ) |>
    dplyr::collect()
  expect_true(all(children_res$h3resolution == 6))
})

testthat::test_that("higher resolution returns more children", {
  res_fine <- ddbh3_get_children(test_data_5, resolution = 7, nested = FALSE) |>
    dplyr::collect()
  res_coarse <- ddbh3_get_children(test_data_5, resolution = 6, nested = FALSE) |>
    dplyr::collect()
  expect_gt(nrow(res_fine), nrow(res_coarse))
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_get_children() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_5_mod <- test_data_5 |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_children(test_data_5_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## ARGUMENT 2 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(7, 8, 9)) {
      res <- ddbh3_get_children(test_data_5, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3children, "character")
    }
  })

  ## ARGUMENT 3 - NESTED
  testthat::it("nested argument works", {
    ## nested = FALSE returns character column (unnested)
    res_false <- ddbh3_get_children(test_data_5, nested = FALSE)
    res_false_col <- dplyr::collect(res_false)
    expect_type(res_false_col$h3children, "character")
    ## nested = TRUE returns list column
    res_true <- ddbh3_get_children(test_data_5, nested = TRUE)
    res_true_col <- dplyr::collect(res_true)
    expect_type(res_true_col$h3children, "list")
  })

  ## ARGUMENT 4 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_children(test_data_5, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 5 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl",
      overwrite = TRUE
    ))
  })

})


## 2.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_5_tbl", dplyr::collect(test_data_5))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_children(test_data_5, h3 = NULL))
    expect_error(ddbh3_get_children(test_data_5, h3 = TRUE))
    expect_error(ddbh3_get_children(test_data_5, h3 = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_get_children(test_data_5, resolution = NULL))
    expect_error(ddbh3_get_children(test_data_5, resolution = "a"))
    expect_error(ddbh3_get_children(test_data_5, resolution = 1.5))
    expect_error(ddbh3_get_children(test_data_5, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_get_children(test_data_5, resolution = -1))
    expect_error(ddbh3_get_children(test_data_5, resolution = 16))
  })

  it("requires nested argument as logical", {
    expect_error(ddbh3_get_children(test_data_5, nested = NULL))
    expect_error(ddbh3_get_children(test_data_5, nested = "yes"))
    expect_error(ddbh3_get_children(test_data_5, nested = 1))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_children(test_data_5, new_column = NULL))
    expect_error(ddbh3_get_children(test_data_5, new_column = FALSE))
    expect_error(ddbh3_get_children(test_data_5, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_children(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_children(test_data_5, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_children(test_data_5, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_children(test_data_5, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_children(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_children(test_data_5, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 3. get_n_children() ---------------------------------------------------------

## 3.1. Input data in different formats ----------

testthat::describe("ddbh3_get_n_children() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_n_children(test_data_5)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_5_df <- dplyr::collect(test_data_5)
    res <- ddbh3_get_n_children(test_data_5_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_5_sf <- test_data_5 |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_n_children(test_data_5_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_5_ddbs <- test_data_5 |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_n_children(test_data_5_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_5_sf <- test_data_5 |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_5_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_n_children("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

})


testthat::test_that("n_children matches actual number of children", {
  ## Get number of children reported by the function
  res_n <- ddbh3_get_n_children(test_data_5, resolution = 10) |>
    dplyr::collect()
  ## Get actual number of children by unnesting
  res_children <- ddbh3_get_children(test_data_5, resolution = 10, nested = FALSE) |>
    dplyr::collect()
  expect_equal(sum(res_n$h3n_children), nrow(res_children))
})

testthat::test_that("n_children is positive", {
  res <- ddbh3_get_n_children(test_data_5, resolution = 10) |>
    dplyr::collect()
  expect_true(all(res$h3n_children > 0))
})

testthat::test_that("finer resolution returns more children", {
  res_fine <- ddbh3_get_n_children(test_data_5, resolution = 11) |>
    dplyr::collect()
  res_coarse <- ddbh3_get_n_children(test_data_5, resolution = 9) |>
    dplyr::collect()
  expect_true(all(res_fine$h3n_children > res_coarse$h3n_children))
})


## 3.2. Arguments work ------------

testthat::describe("ddbh3_get_n_children() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_5_mod <- test_data_5 |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_n_children(test_data_5_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3n_children", colnames(res_col))
    expect_type(res_col$h3n_children, "double")
  })

  ## ARGUMENT 2 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(9, 11, 13, 15)) {
      res <- ddbh3_get_n_children(test_data_5, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3n_children, "double")
    }
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_n_children(test_data_5, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "double")
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_n_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_n_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_n_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_n_children(
      dplyr::collect(test_data_5),
      new_column = "res",
      conn = conn_test,
      name = "test_data_5_tbl",
      overwrite = TRUE
    ))
  })

})


## 3.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_5_tbl", dplyr::collect(test_data_5))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_n_children(test_data_5, h3 = NULL))
    expect_error(ddbh3_get_n_children(test_data_5, h3 = TRUE))
    expect_error(ddbh3_get_n_children(test_data_5, h3 = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_get_n_children(test_data_5, resolution = NULL))
    expect_error(ddbh3_get_n_children(test_data_5, resolution = "a"))
    expect_error(ddbh3_get_n_children(test_data_5, resolution = 1.5))
    expect_error(ddbh3_get_n_children(test_data_5, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_get_n_children(test_data_5, resolution = -1))
    expect_error(ddbh3_get_n_children(test_data_5, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_n_children(test_data_5, new_column = NULL))
    expect_error(ddbh3_get_n_children(test_data_5, new_column = FALSE))
    expect_error(ddbh3_get_n_children(test_data_5, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_error(
      ddbh3_get_n_children("test_data_5_tbl", conn = NULL),
      "If `x` is a table, `conn` cannot be NULL"
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_n_children(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_n_children(test_data_5, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_n_children(test_data_5, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_n_children(test_data_5, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_n_children(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_n_children(test_data_5, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 4. get_center_child() ---------------------------------------------------------

## 4.1. Input data in different formats ----------

testthat::describe("ddbh3_get_center_child() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_center_child(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_center_child(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_center_child(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_center_child(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_center_child("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

})


testthat::test_that("center child has the requested resolution", {
  res <- ddbh3_get_center_child(test_data, resolution = 10) |>
    dplyr::collect()
  ## Verify resolution of center child cells
  child_res <- ddbh3_get_resolution(
    data.frame(h3string = res$h3center_child)
  ) |>
    dplyr::collect()
  expect_true(all(child_res$h3resolution == 10))
})

testthat::test_that("center child is among the children", {
  ## Get center child
  res_center <- ddbh3_get_center_child(test_data, resolution = 10) |>
    dplyr::collect()
  ## Get all children
  res_children <- ddbh3_get_children(test_data, resolution = 10, nested = FALSE) |>
    dplyr::collect()
  ## Center child must be a subset of all children
  expect_true(all(res_center$h3center_child %in% res_children$h3children))
})

testthat::test_that("returns one row per input row", {
  res <- ddbh3_get_center_child(test_data, resolution = 10) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("different resolutions return different center children", {
  res_fine <- ddbh3_get_center_child(test_data, resolution = 11) |>
    dplyr::collect()
  res_coarse <- ddbh3_get_center_child(test_data, resolution = 9) |>
    dplyr::collect()
  expect_false(identical(res_fine$h3center_child, res_coarse$h3center_child))
})


## 4.2. Arguments work ------------

testthat::describe("ddbh3_get_center_child() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_center_child(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3center_child", colnames(res_col))
    expect_type(res_col$h3center_child, "character")
  })

  ## ARGUMENT 2 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(9, 11, 13, 15)) {
      res <- ddbh3_get_center_child(test_data, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3center_child, "character")
    }
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_center_child(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_center_child(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_center_child(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_center_child(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_center_child(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 4.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_center_child(test_data, h3 = NULL))
    expect_error(ddbh3_get_center_child(test_data, h3 = TRUE))
    expect_error(ddbh3_get_center_child(test_data, h3 = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_get_center_child(test_data, resolution = NULL))
    expect_error(ddbh3_get_center_child(test_data, resolution = "a"))
    expect_error(ddbh3_get_center_child(test_data, resolution = 1.5))
    expect_error(ddbh3_get_center_child(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_get_center_child(test_data, resolution = -1))
    expect_error(ddbh3_get_center_child(test_data, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_center_child(test_data, new_column = NULL))
    expect_error(ddbh3_get_center_child(test_data, new_column = FALSE))
    expect_error(ddbh3_get_center_child(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_error(
      ddbh3_get_center_child("test_data_5_tbl", conn = NULL),
      "If `x` is a table, `conn` cannot be NULL"
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_center_child(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_center_child(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_center_child(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_center_child(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_center_child(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_center_child(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 5. get_icosahedron_faces() ---------------------------------------------------------

## 5.1. Input data in different formats ----------

testthat::describe("ddbh3_get_icosahedron_faces() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_icosahedron_faces(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_icosahedron_faces(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_icosahedron_faces(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_icosahedron_faces(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_icosahedron_faces("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

})


# testthat::test_that("unnested result has more rows than nested", {
#   ## Unnested (default): one row per face
#   res_unnested <- ddbh3_get_icosahedron_faces(test_data, nested = FALSE) |>
#     dplyr::collect()
#   ## Nested: one row per cell, faces column contains a list
#   res_nested <- ddbh3_get_icosahedron_faces(test_data, nested = TRUE) |>
#     dplyr::collect()
#   expect_gt(nrow(res_unnested), nrow(res_nested))
# })

testthat::test_that("nested result has same number of rows as input", {
  res_nested <- ddbh3_get_icosahedron_faces(test_data, nested = TRUE) |>
    dplyr::collect()
  expect_equal(nrow(res_nested), nrow(dplyr::collect(test_data)))
})

testthat::test_that("face indices are within valid range", {
  ## Icosahedron has 20 faces, indexed 0-19
  res <- ddbh3_get_icosahedron_faces(test_data, nested = FALSE) |>
    dplyr::collect()
  expect_true(all(res$h3faces >= 0 & res$h3faces <= 19))
})


## 5.2. Arguments work ------------

testthat::describe("ddbh3_get_icosahedron_faces() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_icosahedron_faces(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3faces", colnames(res_col))
    expect_type(res_col$h3faces, "integer")
  })

  ## ARGUMENT 2 - NESTED
  testthat::it("nested argument works", {
    ## nested = FALSE returns integer column (unnested)
    res_false <- ddbh3_get_icosahedron_faces(test_data, nested = FALSE)
    res_false_col <- dplyr::collect(res_false)
    expect_type(res_false_col$h3faces, "integer")
    ## nested = TRUE returns list column
    res_true <- ddbh3_get_icosahedron_faces(test_data, nested = TRUE)
    res_true_col <- dplyr::collect(res_true)
    expect_type(res_true_col$h3faces, "list")
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_icosahedron_faces(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "integer")
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_icosahedron_faces(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_icosahedron_faces(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_icosahedron_faces(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_icosahedron_faces(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 5.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, h3 = NULL))
    expect_error(ddbh3_get_icosahedron_faces(test_data, h3 = TRUE))
    expect_error(ddbh3_get_icosahedron_faces(test_data, h3 = 2))
  })

  it("requires nested argument as logical", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, nested = NULL))
    expect_error(ddbh3_get_icosahedron_faces(test_data, nested = "yes"))
    expect_error(ddbh3_get_icosahedron_faces(test_data, nested = 1))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, new_column = NULL))
    expect_error(ddbh3_get_icosahedron_faces(test_data, new_column = FALSE))
    expect_error(ddbh3_get_icosahedron_faces(test_data, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_icosahedron_faces(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_icosahedron_faces(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_icosahedron_faces(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 6. get_child_pos() ---------------------------------------------------------

## 6.1. Input data in different formats ----------

testthat::describe("ddbh3_get_child_pos() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_child_pos(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_child_pos(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_child_pos(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_child_pos(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_child_pos("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

})


testthat::test_that("child position is non-negative", {
  res <- ddbh3_get_child_pos(test_data, resolution = 10) |>
    dplyr::collect()
  expect_true(all(res$h3child_pos >= 0))
})

testthat::test_that("child position is within the number of children at that resolution", {
  resolution <- 10
  ## Get child positions
  res_pos <- ddbh3_get_child_pos(test_data, resolution = resolution) |>
    dplyr::collect()
  ## Get number of children at that resolution
  res_n <- ddbh3_get_n_children(test_data, resolution = resolution) |>
    dplyr::collect()
  ## Position must be strictly less than the number of children
  expect_true(all(res_pos$h3child_pos < res_n$h3n_children))
})

testthat::test_that("returns one row per input row", {
  res <- ddbh3_get_child_pos(test_data, resolution = 10) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("different resolutions return different positions", {
  res_fine <- ddbh3_get_child_pos(test_data, resolution = 11) |>
    dplyr::collect()
  res_coarse <- ddbh3_get_child_pos(test_data, resolution = 9) |>
    dplyr::collect()
  expect_false(identical(res_fine$h3child_pos, res_coarse$h3child_pos))
})


## 6.2. Arguments work ------------

testthat::describe("ddbh3_get_child_pos() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_child_pos(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3child_pos", colnames(res_col))
    expect_type(res_col$h3child_pos, "double")
  })

  ## ARGUMENT 2 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(9, 11, 13, 15)) {
      res <- ddbh3_get_child_pos(test_data, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3child_pos, "double")
    }
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_child_pos(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "double")
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_child_pos(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_child_pos(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_child_pos(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_child_pos(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 6.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_child_pos(test_data, h3 = NULL))
    expect_error(ddbh3_get_child_pos(test_data, h3 = TRUE))
    expect_error(ddbh3_get_child_pos(test_data, h3 = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_get_child_pos(test_data, resolution = NULL))
    expect_error(ddbh3_get_child_pos(test_data, resolution = "a"))
    expect_error(ddbh3_get_child_pos(test_data, resolution = 1.5))
    expect_error(ddbh3_get_child_pos(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_get_child_pos(test_data, resolution = -1))
    expect_error(ddbh3_get_child_pos(test_data, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_child_pos(test_data, new_column = NULL))
    expect_error(ddbh3_get_child_pos(test_data, new_column = FALSE))
    expect_error(ddbh3_get_child_pos(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_error(
      ddbh3_get_child_pos("test_data_tbl", conn = NULL)
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_child_pos(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_child_pos(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_child_pos(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_child_pos(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_child_pos(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_child_pos(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})



# 7. get_base_cell_number() ---------------------------------------------------------

## 7.1. Input data in different formats ----------

testthat::describe("ddbh3_get_base_cell_number() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_base_cell_number(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_base_cell_number(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_get_base_cell_number(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_base_cell_number(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_base_cell_number("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

})

testthat::test_that("result has same number of rows as input", {
  res <- ddbh3_get_base_cell_number(test_data) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("base cell numbers are within valid range", {
  ## H3 has base cells indexed 0 to 121
  res <- ddbh3_get_base_cell_number(test_data) |>
    dplyr::collect()
  expect_true(all(res$base_cell >= 0 & res$base_cell <= 121))
})


## 7.2. Arguments work ------------

testthat::describe("ddbh3_get_base_cell_number() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_base_cell_number(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("base_cell", colnames(res_col))
    expect_type(res_col$base_cell, "integer")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_base_cell_number(test_data, new_column = "my_base_cell")
    expect_true("my_base_cell" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("my_base_cell", colnames(res_col))
    expect_type(res_col$my_base_cell, "integer")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_base_cell_number(
      dplyr::collect(test_data),
      new_column = "base_cell",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_get_base_cell_number(
      dplyr::collect(test_data),
      new_column = "base_cell",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_base_cell_number(
      dplyr::collect(test_data),
      new_column = "base_cell",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_base_cell_number(
      dplyr::collect(test_data),
      new_column = "base_cell",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 7.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_base_cell_number(test_data, h3 = NULL))
    expect_error(ddbh3_get_base_cell_number(test_data, h3 = TRUE))
    expect_error(ddbh3_get_base_cell_number(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_base_cell_number(test_data, new_column = NULL))
    expect_error(ddbh3_get_base_cell_number(test_data, new_column = FALSE))
    expect_error(ddbh3_get_base_cell_number(test_data, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_get_base_cell_number(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_get_base_cell_number(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_get_base_cell_number(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_get_base_cell_number(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_get_base_cell_number(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_get_base_cell_number(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})



## 7.4. Correctness, H3 types and mode -----------

testthat::describe("ddbh3_get_base_cell_number() returns correct values", {

  testthat::it("returns a known base cell", {
    res <- ddbh3_get_base_cell_number(data.frame(h3string = "883923059bfffff")) |>
      dplyr::collect()
    expect_equal(res$base_cell, 28)
  })

  testthat::it("works with UBIGINT h3 column", {
    res_big <- ddbh3_strings_to_bigint(test_data) |>
      ddbh3_get_base_cell_number(h3 = "h3bigint") |>
      dplyr::collect()
    res_str <- ddbh3_get_base_cell_number(test_data) |>
      dplyr::collect()
    expect_equal(res_big$base_cell, res_str$base_cell)
  })

  testthat::it("works with character and UBIGINT vectors", {
    expect_equal(ddbh3_get_base_cell_number("883923059bfffff"), 28)
    expect_equal(
      ddbh3_get_base_cell_number(ddbh3_strings_to_bigint("883923059bfffff")),
      28
    )
  })

  testthat::it("children share the base cell of their parent", {
    res <- ddbh3_get_parent(test_data, resolution = 2) |>
      ddbh3_get_base_cell_number(new_column = "bc_child") |>
      ddbh3_get_base_cell_number(h3 = "h3parent", new_column = "bc_parent") |>
      dplyr::collect()
    expect_equal(res$bc_child, res$bc_parent)
  })

  testthat::it("mode argument works", {
    test_data_sf <- test_data |>
      dplyr::collect() |>
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    expect_s3_class(ddbh3_get_base_cell_number(test_data_sf, mode = "sf"), "sf")
    expect_s3_class(ddbh3_get_base_cell_number(test_data_sf, mode = "duckspatial"), "duckspatial_df")
  })

})



# 8. child_pos_to_cell() ---------------------------------------------------------

## Input with a parent at resolution 9 and the child position of each cell
test_data_cp <- test_data |>
  ddbh3_get_parent(resolution = 9) |>
  ddbh3_get_child_pos(resolution = 9)

test_data_cp_df <- dplyr::collect(test_data_cp)

## 8.1. Input data in different formats ----------

testthat::describe("ddbh3_child_pos_to_cell() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 10)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_child_pos_to_cell(test_data_cp_df, parent = "h3parent", resolution = 10)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    test_data_sf <- test_data_cp_df |>
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    res <- ddbh3_child_pos_to_cell(test_data_sf, parent = "h3parent", resolution = 10)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    test_data_ddbs <- test_data_cp_df |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    res <- ddbh3_child_pos_to_cell(test_data_ddbs, parent = "h3parent", resolution = 10)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    conn_test <- ddbh3_create_conn()
    test_data_sf <- test_data_cp_df |>
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_child_pos_to_cell("sf_pts", parent = "h3parent", resolution = 10, conn = conn_test)
    res_col <- dplyr::collect(res)
    expect_in("h3children", colnames(res_col))
    expect_type(res_col$h3children, "character")
  })

  ## FORMAT 6 - VECTORIZED
  testthat::it("works with vectors", {
    testthat::skip("bug (#8): vectorized base_fun references `y`, which get_vectorized_result() never binds")
    expect_equal(
      ddbh3_child_pos_to_cell(0, parent = "873923059ffffff"),
      "8839230591fffff"
    )
  })

})


## 8.2. Correctness ------------

testthat::describe("ddbh3_child_pos_to_cell() returns correct cells", {

  testthat::it("round trips with get_child_pos()", {
    res <- ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 10) |>
      dplyr::collect()
    expect_equal(res$h3children, res$h3string)
  })

  testthat::it("returns a known child", {
    res <- data.frame(h3child_pos = 0L, h3string = "873923059ffffff") |>
      ddbh3_child_pos_to_cell(resolution = 8) |>
      dplyr::collect()
    expect_equal(res$h3children, "8839230591fffff")
  })

  testthat::it("accepts child positions stored as double", {
    testthat::skip("bug (#8): h3_child_pos_to_cell() has no DOUBLE signature and child_pos is not cast to BIGINT")
    res <- data.frame(h3child_pos = 0, h3string = "873923059ffffff") |>
      ddbh3_child_pos_to_cell(resolution = 8) |>
      dplyr::collect()
    expect_equal(res$h3children, "8839230591fffff")
  })

  testthat::it("position 0 is the center child", {
    res <- test_data_cp_df |>
      dplyr::mutate(pos0 = 0L) |>
      ddbh3_child_pos_to_cell(child_pos = "pos0", parent = "h3parent", resolution = 10) |>
      ddbh3_get_center_child(h3 = "h3parent", resolution = 10) |>
      dplyr::collect()
    expect_equal(res$h3children, res$h3center_child)
  })

  testthat::it("children have the requested resolution", {
    res <- ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 10) |>
      dplyr::collect()
    expect_true(all(ddbh3_get_resolution(res$h3children) == 10))
  })

})


## 8.3. Arguments work ------------

testthat::describe("ddbh3_child_pos_to_cell() arguments work", {

  ## ARGUMENT 1 - CHILD_POS AND PARENT
  testthat::it("child_pos and parent arguments work", {
    test_data_mod <- test_data_cp |>
      dplyr::rename(pos = h3child_pos, par = h3parent)
    res <- ddbh3_child_pos_to_cell(test_data_mod, child_pos = "pos", parent = "par", resolution = 10) |>
      dplyr::collect()
    expect_equal(res$h3children, res$h3string)
  })

  testthat::it("works with UBIGINT parent column", {
    res <- test_data_cp |>
      ddbh3_strings_to_bigint(h3 = "h3parent", new_column = "parent_big") |>
      ddbh3_child_pos_to_cell(parent = "parent_big", resolution = 10) |>
      dplyr::collect()
    expect_s3_class(res$h3children, "integer64")
    expect_equal(ddbh3_bigint_to_strings(res$h3children), res$h3string)
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 10, new_column = "my_child")
    expect_true("my_child" %in% colnames(res))
  })

  ## ARGUMENT 3 - MODE
  testthat::it("mode argument works", {
    test_data_sf <- test_data_cp_df |>
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    expect_s3_class(
      ddbh3_child_pos_to_cell(test_data_sf, parent = "h3parent", resolution = 10, mode = "sf"),
      "sf"
    )
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    conn_test <- ddbh3_create_conn()
    expect_message(ddbh3_child_pos_to_cell(
      test_data_cp_df, parent = "h3parent", resolution = 10,
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_no_message(ddbh3_child_pos_to_cell(
      test_data_cp_df, parent = "h3parent", resolution = 10,
      conn = conn_test, name = "test_data_tbl2", quiet = TRUE
    ))
    expect_error(ddbh3_child_pos_to_cell(
      test_data_cp_df, parent = "h3parent", resolution = 10,
      conn = conn_test, name = "test_data_tbl"
    ))
    expect_true(ddbh3_child_pos_to_cell(
      test_data_cp_df, parent = "h3parent", resolution = 10,
      conn = conn_test, name = "test_data_tbl", overwrite = TRUE
    ))
  })

})


## 8.4. Errors on weird inputs -----------

describe("ddbh3_child_pos_to_cell() errors", {

  conn_test <- ddbh3_create_conn()

  it("requires child_pos and parent as character", {
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, child_pos = 1, parent = "h3parent"))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, child_pos = NULL, parent = "h3parent"))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = TRUE))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = c("h3parent", "h3string")))
  })

  it("requires a valid resolution", {
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 16))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = -1))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = 9.5))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", resolution = c(9, 10)))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", new_column = 25))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "not_a_column", resolution = 10))
  })

  it("validates x, conn, overwrite and quiet", {
    expect_error(ddbh3_child_pos_to_cell(x = TRUE))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", conn = 999))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", overwrite = 999))
    expect_error(ddbh3_child_pos_to_cell(test_data_cp, parent = "h3parent", quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_child_pos_to_cell(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_child_pos_to_cell(
      test_data_cp, parent = "h3parent", conn = conn_test, name = c("banana", "banana")
    ))
  })

})
