
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
)


# 1. lonlat_to_h3() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_lonlat_to_h3() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_lonlat_to_h3(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_lonlat_to_h3(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
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
    res <- ddbh3_lonlat_to_h3(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_lonlat_to_h3(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
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
    res <- ddbh3_lonlat_to_h3("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

})


testthat::test_that("string format returns valid h3 cells", {
  res <- ddbh3_lonlat_to_h3(test_data, resolution = 8, h3_format = "string") |>
    dplyr::collect()
  ## Validate returned cells are valid h3 strings
  validity <- ddbh3_is_h3(data.frame(h3string = res$h3string)) |>
    dplyr::collect()
  expect_true(all(validity$ish3))
})

testthat::test_that("bigint format returns valid h3 cells", {
  res <- ddbh3_lonlat_to_h3(test_data, resolution = 8, h3_format = "bigint") |>
    dplyr::collect()
  ## bigint output should be integer64 type
  expect_true(inherits(res$h3string, "integer64"))
})

testthat::test_that("returned cells have the requested resolution", {
  res <- ddbh3_lonlat_to_h3(test_data, resolution = 5, h3_format = "string") |>
    dplyr::collect()
  ## Verify resolution of returned cells
  res_resolution <- ddbh3_get_resolution(
    data.frame(h3string = res$h3string)
  ) |>
    dplyr::collect()
  expect_true(all(res_resolution$h3resolution == 5))
})

testthat::test_that("different resolutions return different cells", {
  res_fine <- ddbh3_lonlat_to_h3(test_data, resolution = 10) |>
    dplyr::collect()
  res_coarse <- ddbh3_lonlat_to_h3(test_data, resolution = 5) |>
    dplyr::collect()
  expect_false(identical(res_fine$h3string, res_coarse$h3string))
})

testthat::test_that("returns one row per input row", {
  res <- ddbh3_lonlat_to_h3(test_data, resolution = 8) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_lonlat_to_h3() arguments work", {

  ## ARGUMENT 1 - LON
  testthat::it("lon argument works", {
    ## Rename lon column
    test_data_mod <- test_data |>
      dplyr::rename(longitude = lon)
    ## Apply operation with new lon column name
    res <- ddbh3_lonlat_to_h3(test_data_mod, lon = "longitude")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## ARGUMENT 2 - LAT
  testthat::it("lat argument works", {
    ## Rename lat column
    test_data_mod <- test_data |>
      dplyr::rename(latitude = lat)
    ## Apply operation with new lat column name
    res <- ddbh3_lonlat_to_h3(test_data_mod, lat = "latitude")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "character")
  })

  ## ARGUMENT 3 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(0, 3, 7, 15)) {
      res <- ddbh3_lonlat_to_h3(test_data, resolution = r)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3string, "character")
    }
  })

  ## ARGUMENT 4 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_lonlat_to_h3(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 5 - H3_FORMAT
  testthat::it("h3_format argument works", {
    ## string format returns character
    res_string <- ddbh3_lonlat_to_h3(test_data, h3_format = "string")
    res_string_col <- dplyr::collect(res_string)
    expect_type(res_string_col$h3string, "character")
    ## bigint format returns integer64
    res_bigint <- ddbh3_lonlat_to_h3(test_data, h3_format = "bigint")
    res_bigint_col <- dplyr::collect(res_bigint)
    expect_true(inherits(res_bigint_col$h3string, "integer64"))
  })

  ## ARGUMENT 6 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_lonlat_to_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_lonlat_to_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_lonlat_to_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_lonlat_to_h3(
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
  it("requires lon argument as character", {
    expect_error(ddbh3_lonlat_to_h3(test_data, lon = NULL))
    expect_error(ddbh3_lonlat_to_h3(test_data, lon = TRUE))
    expect_error(ddbh3_lonlat_to_h3(test_data, lon = 2))
  })

  it("requires lat argument as character", {
    expect_error(ddbh3_lonlat_to_h3(test_data, lat = NULL))
    expect_error(ddbh3_lonlat_to_h3(test_data, lat = TRUE))
    expect_error(ddbh3_lonlat_to_h3(test_data, lat = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = NULL))
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = "a"))
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = 1.5))
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = -1))
    expect_error(ddbh3_lonlat_to_h3(test_data, resolution = 16))
  })

  it("requires h3_format to be a valid option", {
    expect_error(ddbh3_lonlat_to_h3(test_data, h3_format = "invalid"))
    expect_error(ddbh3_lonlat_to_h3(test_data, h3_format = 999))
    expect_error(ddbh3_lonlat_to_h3(test_data, h3_format = NULL))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_lonlat_to_h3(test_data, new_column = NULL))
    expect_error(ddbh3_lonlat_to_h3(test_data, new_column = FALSE))
    expect_error(ddbh3_lonlat_to_h3(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_error(ddbh3_lonlat_to_h3("test_data_tbl", conn = NULL))
  })

  it("validates x argument type", {
    expect_error(ddbh3_lonlat_to_h3(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_lonlat_to_h3(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_lonlat_to_h3(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_lonlat_to_h3(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_lonlat_to_h3(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_lonlat_to_h3(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 2. lonlat_to_spatial() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_lonlat_to_spatial() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_lonlat_to_spatial(test_data)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_lonlat_to_spatial(test_data_df)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
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
    res <- ddbh3_lonlat_to_spatial(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_lonlat_to_spatial(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
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
    res <- ddbh3_lonlat_to_spatial("sf_pts", conn = conn_test)
    ## Check class
    expect_s3_class(res, "duckspatial_df")
    ## Check geometry
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

})


testthat::test_that("returns one row per input row", {
  res <- ddbh3_lonlat_to_spatial(test_data, resolution = 8) |>
    dplyr::collect()
  expect_equal(nrow(res), nrow(dplyr::collect(test_data)))
})

testthat::test_that("geometry column contains polygons", {
  res <- ddbh3_lonlat_to_spatial(test_data, resolution = 8) 
  expect_true(all(sf::st_geometry_type(res) == "POLYGON"))
})

testthat::test_that("different resolutions return different geometries", {
  res_fine <- ddbh3_lonlat_to_spatial(test_data, resolution = 10) |>
    dplyr::collect()
  res_coarse <- ddbh3_lonlat_to_spatial(test_data, resolution = 5) |>
    dplyr::collect()
  expect_false(identical(res_fine$geometry, res_coarse$geometry))
})

testthat::test_that("finer resolution returns smaller polygons", {
  res_fine <- ddbh3_lonlat_to_spatial(test_data, resolution = 10)
  res_coarse <- ddbh3_lonlat_to_spatial(test_data, resolution = 5)
  expect_true(
    all(
      duckspatial::ddbs_area(res_fine, mode = "sf") < duckspatial::ddbs_area(res_coarse, mode = "sf")
    )
  )
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_lonlat_to_spatial() arguments work", {

  ## ARGUMENT 1 - LON
  testthat::it("lon argument works", {
    ## Rename lon column
    test_data_mod <- test_data |>
      dplyr::rename(longitude = lon)
    ## Apply operation with new lon column name
    res <- ddbh3_lonlat_to_spatial(test_data_mod, lon = "longitude")
    ## Check class and geometry
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## ARGUMENT 2 - LAT
  testthat::it("lat argument works", {
    ## Rename lat column
    test_data_mod <- test_data |>
      dplyr::rename(latitude = lat)
    ## Apply operation with new lat column name
    res <- ddbh3_lonlat_to_spatial(test_data_mod, lat = "latitude")
    ## Check class and geometry
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## ARGUMENT 3 - RESOLUTION
  testthat::it("resolution argument works", {
    ## Sample of valid resolutions return results
    for (r in c(0, 3, 7, 15)) {
      res <- ddbh3_lonlat_to_spatial(test_data, resolution = r)
      expect_s3_class(res, "duckspatial_df")
      res_col <- dplyr::collect(res)
      expect_in("geometry", colnames(res_col))
    }
  })

  ## ARGUMENT 4 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_lonlat_to_spatial(
      dplyr::collect(test_data),
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_lonlat_to_spatial(
      dplyr::collect(test_data),
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_lonlat_to_spatial(
      dplyr::collect(test_data),
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_lonlat_to_spatial(
      dplyr::collect(test_data),
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 2.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires lon argument as character", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, lon = NULL))
    expect_error(ddbh3_lonlat_to_spatial(test_data, lon = TRUE))
    expect_error(ddbh3_lonlat_to_spatial(test_data, lon = 2))
  })

  it("requires lat argument as character", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, lat = NULL))
    expect_error(ddbh3_lonlat_to_spatial(test_data, lat = TRUE))
    expect_error(ddbh3_lonlat_to_spatial(test_data, lat = 2))
  })

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = NULL))
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = "a"))
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = 1.5))
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = c(1, 2)))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = -1))
    expect_error(ddbh3_lonlat_to_spatial(test_data, resolution = 16))
  })

  it("requires connection when using table names", {
    expect_error(ddbh3_lonlat_to_spatial("test_data_tbl", conn = NULL))
  })

  it("validates x argument type", {
    expect_error(ddbh3_lonlat_to_spatial(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_lonlat_to_spatial(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_lonlat_to_spatial(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})
