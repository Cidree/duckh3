

# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_create_conn()

## Load example data
test_data <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
) |>
  duckspatial::ddbs_as_points()

# 1. points_to_spatial() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_points_to_spatial() works in different formats", {

  ## FORMAT 1 - SF
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
    res <- ddbh3_points_to_spatial(test_data_sf, resolution = 8)
    expect_s3_class(res, "duckspatial_df")
    ## Check geometry
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## FORMAT 2 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_points_to_spatial(test_data_ddbs, resolution = 8)
    expect_s3_class(res, "duckspatial_df")
    ## Check geometry
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## FORMAT 3 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf and store
    test_data_sf <- test_data |> duckspatial::ddbs_collect()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_points_to_spatial("sf_pts", resolution = 8, conn = conn_test)
    ## Check class
    expect_s3_class(res, "duckspatial_df")
    ## Check geometry
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

})


testthat::test_that("returns one row per input row", {
  res <- ddbh3_points_to_spatial(test_data, resolution = 8) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("geometry column contains polygons", {
  res <- ddbh3_points_to_spatial(test_data, resolution = 8)
  expect_true(all(duckspatial::ddbs_geometry_type(res) == "POLYGON"))
})

testthat::test_that("different resolutions return different geometries", {
  res_fine <- ddbh3_points_to_spatial(test_data, resolution = 10) |>
    dplyr::collect()
  res_coarse <- ddbh3_points_to_spatial(test_data, resolution = 5) |>
    dplyr::collect()
  expect_false(identical(res_fine$geometry, res_coarse$geometry))
})

testthat::test_that("finer resolution returns smaller polygons", {
  res_fine <- ddbh3_points_to_spatial(test_data, resolution = 10) 
  res_coarse <- ddbh3_points_to_spatial(test_data, resolution = 5)
  expect_true(all(
    duckspatial::ddbs_area(res_fine, mode = "sf") < 
      duckspatial::ddbs_area(res_coarse, mode = "sf")
  ))
})

testthat::test_that("rejects non-EPSG:4326 input", {
  ## Project to a different CRS
  test_data_3857 <- test_data |>
    duckspatial::ddbs_transform(3857)
  expect_error(ddbh3_points_to_spatial(test_data_3857, resolution = 8))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_points_to_spatial() arguments work", {

  ## ARGUMENT 1 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(0, 3, 7, 15)) {
      res <- ddbh3_points_to_spatial(test_data, resolution = r)
      expect_s3_class(res, "duckspatial_df")
      res_col <- dplyr::collect(res)
      expect_in("geometry", colnames(res_col))
    }
  })

  ## ARGUMENT 2 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    test_data_sf <- duckspatial::ddbs_collect(test_data)
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_points_to_spatial(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_points_to_spatial(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_points_to_spatial(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_points_to_spatial(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 1.3. Errors on weird inputs -----------

describe("errors", {

  ## Prepare sf input and connection
  conn_test <- ddbh3_create_conn()
  duckspatial::ddbs_write_table(conn_test, dplyr::collect(test_data), "sf_pts")

  ## Tests
  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_points_to_spatial(test_data, resolution = NULL))
    expect_error(ddbh3_points_to_spatial(test_data, resolution = "a"))
    expect_error(ddbh3_points_to_spatial(test_data, resolution = 1.5))
    expect_error(ddbh3_points_to_spatial(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_points_to_spatial(test_data, resolution = -1))
    expect_error(ddbh3_points_to_spatial(test_data, resolution = 16))
  })

  it("requires point geometry input", {
    ## Create a polygon input instead of points
    test_data_poly <- test_data |>
      ddbh3_lonlat_to_spatial(resolution = 8)
    expect_error(ddbh3_points_to_spatial(test_data_poly, resolution = 8))
  })

  it("requires EPSG:4326 CRS", {
    test_data_projected <- test_data |>
      duckspatial::ddbs_transform(3857)
    expect_error(ddbh3_points_to_spatial(test_data_projected, resolution = 8))
  })

  it("requires connection when using table names", {
    expect_error(ddbh3_points_to_spatial("sf_pts", resolution = 8, conn = NULL))
  })

  it("validates x argument type", {
    expect_error(ddbh3_points_to_spatial(x = 999, resolution = 8))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_points_to_spatial(test_data, resolution = 8, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_points_to_spatial(test_data, resolution = 8, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_points_to_spatial(test_data, resolution = 8, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_points_to_spatial("999", resolution = 8, conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_points_to_spatial(
      test_data,
      resolution = 8,
      conn = conn_test,
      name = c("banana", "banana")
    ))
  })

})



# 2. points_to_h3() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_points_to_h3() works in different formats", {

  ## FORMAT 1 - SF
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
    res <- ddbh3_points_to_h3(test_data_sf, resolution = 8)
    expect_s3_class(res, "duckspatial_df")
    ## Check column
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## FORMAT 2 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_points_to_h3(test_data_ddbs, resolution = 8)
    expect_s3_class(res, "duckspatial_df")
    ## Check column
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## FORMAT 3 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Store table in connection
    test_data_sf <- duckspatial::ddbs_collect(test_data)
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_points_to_h3("sf_pts", resolution = 8, conn = conn_test)
    ## Check class
    expect_s3_class(res, "duckspatial_df")
    ## Check column
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

})


testthat::test_that("returns one row per input row", {
  res <- ddbh3_points_to_h3(test_data, resolution = 8) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("geometry column is preserved", {
  res <- ddbh3_points_to_h3(test_data, resolution = 8) |>
    dplyr::collect()
  expect_in("geometry", colnames(res))
})

testthat::test_that("string format returns valid h3 cells", {
  res <- ddbh3_points_to_h3(test_data, resolution = 8, h3_format = "string") |>
    dplyr::collect()
  validity <- ddbh3_is_h3(data.frame(h3string = res$h3string)) |>
    dplyr::collect()
  expect_true(all(validity$ish3))
})

testthat::test_that("bigint format returns integer64 column", {
  res <- ddbh3_points_to_h3(test_data, resolution = 8, h3_format = "bigint") |>
    dplyr::collect()
  expect_true(inherits(res$h3string, "integer64"))
})

testthat::test_that("returned cells have the requested resolution", {
  res <- ddbh3_points_to_h3(test_data, resolution = 5, h3_format = "string") |>
    dplyr::collect()
  res_resolution <- ddbh3_get_resolution(
    data.frame(h3string = res$h3string)
  ) |>
    dplyr::collect()
  expect_true(all(res_resolution$h3resolution == 5))
})

testthat::test_that("different resolutions return different cells", {
  res_fine <- ddbh3_points_to_h3(test_data, resolution = 10) |>
    dplyr::collect()
  res_coarse <- ddbh3_points_to_h3(test_data, resolution = 5) |>
    dplyr::collect()
  expect_false(identical(res_fine$h3string, res_coarse$h3string))
})

testthat::test_that("rejects non-EPSG:4326 input", {
  test_data_3857 <- test_data |>
    duckspatial::ddbs_transform(3857)
  expect_error(ddbh3_points_to_h3(test_data_3857, resolution = 8))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_points_to_h3() arguments work", {

  ## ARGUMENT 1 - RESOLUTION
  testthat::it("resolution argument works", {
    for (r in c(0, 3, 7, 15)) {
      res <- ddbh3_points_to_h3(test_data, resolution = r)
      expect_s3_class(res, "duckspatial_df")
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3string, "character")
    }
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_points_to_h3(test_data, resolution = 8, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 3 - H3_FORMAT
  testthat::it("h3_format argument works", {
    ## string format returns character
    res_string <- ddbh3_points_to_h3(test_data, resolution = 8, h3_format = "string")
    res_string_col <- dplyr::collect(res_string)
    expect_type(res_string_col$h3string, "character")
    ## bigint format returns integer64
    res_bigint <- ddbh3_points_to_h3(test_data, resolution = 8, h3_format = "bigint")
    res_bigint_col <- dplyr::collect(res_bigint)
    expect_true(inherits(res_bigint_col$h3string, "integer64"))
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    test_data_sf <- duckspatial::ddbs_collect(test_data)
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_points_to_h3(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_points_to_h3(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_points_to_h3(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_points_to_h3(
      test_data_sf,
      resolution = 8,
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 1.3. Errors on weird inputs -----------

describe("errors", {

  ## Prepare connection
  conn_test <- ddbh3_create_conn()
  duckspatial::ddbs_write_table(conn_test, dplyr::collect(test_data), "sf_pts")

  ## Tests
  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = NULL))
    expect_error(ddbh3_points_to_h3(test_data, resolution = "a"))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 1.5))
    expect_error(ddbh3_points_to_h3(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = -1))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, new_column = NULL))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, new_column = FALSE))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, new_column = 25))
  })

  it("requires h3_format to be a valid option", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, h3_format = "invalid"))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, h3_format = 999))
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, h3_format = NULL))
  })

  it("requires point geometry input", {
    test_data_poly <- test_data |>
      ddbh3_lonlat_to_spatial(resolution = 8)
    expect_error(ddbh3_points_to_h3(test_data_poly, resolution = 8))
  })

  it("requires EPSG:4326 CRS", {
    test_data_projected <- test_data |>
      duckspatial::ddbs_transform(3857)
    expect_error(ddbh3_points_to_h3(test_data_projected, resolution = 8))
  })

  it("requires connection when using table names", {
    expect_error(ddbh3_points_to_h3("sf_pts", resolution = 8, conn = NULL))
  })

  it("validates x argument type", {
    expect_error(ddbh3_points_to_h3(x = 999, resolution = 8))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_points_to_h3(test_data, resolution = 8, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_points_to_h3("999", resolution = 8, conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_points_to_h3(
      test_data,
      resolution = 8,
      conn = conn_test,
      name = c("banana", "banana")
    ))
  })

})
