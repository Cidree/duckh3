

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
  ddbh3_lonlat_to_h3(resolution = 10)

## Get data with vertex
test_data_vertex <- ddbh3_h3_to_vertex(test_data)
test_data_nested <- ddbh3_h3_to_vertexes(test_data, nested = TRUE)

# 1. h3_to_vertex() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_vertex() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_h3_to_vertex(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_h3_to_vertex(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
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
    res <- ddbh3_h3_to_vertex(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_h3_to_vertex(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
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
    res <- ddbh3_h3_to_vertex("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

})


testthat::test_that("returns a valid vertex string", {
  cell_df <- data.frame(h3string = "8ad02dcc1947fff")
  res <- ddbh3_h3_to_vertex(cell_df, n = 0)
  res_col <- dplyr::collect(res)
  expect_type(res_col$h3vertex, "character")
  expect_true(nchar(res_col$h3vertex) > 0)
})

testthat::test_that("different vertex indices return different vertices", {
  cell_df <- data.frame(h3string = "8ad02dcc1947fff")
  res_0 <- dplyr::collect(ddbh3_h3_to_vertex(cell_df, n = 0))
  res_1 <- dplyr::collect(ddbh3_h3_to_vertex(cell_df, n = 1))
  expect_false(res_0$h3vertex == res_1$h3vertex)
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_h3_to_vertex() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_h3_to_vertex(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## ARGUMENT 2 - N
  testthat::it("n argument works", {
    ## All valid vertex indices return results
    for (i in 0:5) {
      res <- ddbh3_h3_to_vertex(test_data, n = i)
      res_col <- dplyr::collect(res)
      expect_type(res_col$h3vertex, "character")
    }
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_vertex(test_data, new_column = "res")
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
    expect_message(ddbh3_h3_to_vertex(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_h3_to_vertex(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_h3_to_vertex(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_h3_to_vertex(
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
    expect_error(ddbh3_h3_to_vertex(test_data, h3 = NULL))
    expect_error(ddbh3_h3_to_vertex(test_data, h3 = TRUE))
    expect_error(ddbh3_h3_to_vertex(test_data, h3 = 2))
  })

  it("requires n to be an integer scalar", {
    expect_error(ddbh3_h3_to_vertex(test_data, n = NULL))
    expect_error(ddbh3_h3_to_vertex(test_data, n = "a"))
    expect_error(ddbh3_h3_to_vertex(test_data, n = 1.5))
    expect_error(ddbh3_h3_to_vertex(test_data, n = c(1, 2)))
  })

  it("requires n to be in the range 0-5", {
    expect_error(ddbh3_h3_to_vertex(test_data, n = -1))
    expect_error(ddbh3_h3_to_vertex(test_data, n = 6))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_h3_to_vertex(test_data, new_column = NULL))
    expect_error(ddbh3_h3_to_vertex(test_data, new_column = FALSE))
    expect_error(ddbh3_h3_to_vertex(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_h3_to_vertex("test_data_tbl", conn = NULL)))
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_h3_to_vertex(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_h3_to_vertex(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_h3_to_vertex(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_h3_to_vertex(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_h3_to_vertex(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_h3_to_vertex(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 2. vertex_to_lon() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_vertex_to_lon() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_vertex_to_lon(test_data_vertex)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data_vertex)
    res <- ddbh3_vertex_to_lon(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_vertex_to_lon(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data_vertex |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_vertex_to_lon(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_vertex_to_lon("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

})


testthat::test_that("returns a numeric longitude value", {
  vertex_df <- data.frame(h3vertex = "2222597fffffffff")
  res <- ddbh3_vertex_to_lon(vertex_df)
  res_col <- dplyr::collect(res)
  expect_type(res_col$lon_vertex, "double")
  expect_true(res_col$lon_vertex >= -180 & res_col$lon_vertex <= 180)
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_vertex_to_lon() arguments work", {

  ## ARGUMENT 1 - H3VERTEX
  testthat::it("h3vertex argument works", {
    ## Rename h3vertex column
    test_data_mod <- test_data_vertex |>
      dplyr::rename(vertex = h3vertex)
    ## Apply operation with new h3vertex column name
    res <- ddbh3_vertex_to_lon(test_data_mod, h3vertex = "vertex")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lon_vertex", colnames(res_col))
    expect_type(res_col$lon_vertex, "double")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_vertex_to_lon(test_data_vertex, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "double")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_vertex_to_lon(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_vertex_to_lon(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_vertex_to_lon(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_vertex_to_lon(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 2.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3vertex strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data_vertex))

  ## Tests
  it("requires h3vertex argument as character", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, h3vertex = NULL))
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, h3vertex = TRUE))
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, h3vertex = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, new_column = NULL))
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, new_column = FALSE))
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_vertex_to_lon("test_data_tbl", conn = NULL)))
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_vertex_to_lon(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_vertex_to_lon(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_vertex_to_lon(test_data_vertex, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 3. vertex_to_lat() ---------------------------------------------------------

## 3.1. Input data in different formats ----------

testthat::describe("ddbh3_vertex_to_lat() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_vertex_to_lat(test_data_vertex)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data_vertex)
    res <- ddbh3_vertex_to_lat(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_vertex_to_lat(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data_vertex |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_vertex_to_lat(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to sf
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_vertex_to_lat("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

})


testthat::test_that("returns a numeric latitude value", {
  vertex_df <- data.frame(h3vertex = "2222597fffffffff")
  res <- ddbh3_vertex_to_lat(vertex_df)
  res_col <- dplyr::collect(res)
  expect_type(res_col$lat_vertex, "double")
  expect_true(res_col$lat_vertex >= -90 & res_col$lat_vertex <= 90)
})


## 3.2. Arguments work ------------

testthat::describe("ddbh3_vertex_to_lat() arguments work", {

  ## ARGUMENT 1 - H3VERTEX
  testthat::it("h3vertex argument works", {
    ## Rename h3vertex column
    test_data_mod <- test_data_vertex |>
      dplyr::rename(vertex = h3vertex)
    ## Apply operation with new h3vertex column name
    res <- ddbh3_vertex_to_lat(test_data_mod, h3vertex = "vertex")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("lat_vertex", colnames(res_col))
    expect_type(res_col$lat_vertex, "double")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_vertex_to_lat(test_data_vertex, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "double")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_vertex_to_lat(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_vertex_to_lat(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_vertex_to_lat(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_vertex_to_lat(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 3.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3vertex strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data_vertex))

  ## Tests
  it("requires h3vertex argument as character", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, h3vertex = NULL))
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, h3vertex = TRUE))
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, h3vertex = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, new_column = NULL))
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, new_column = FALSE))
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_vertex_to_lat("test_data_tbl", conn = NULL)))
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_vertex_to_lat(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_vertex_to_lat(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_vertex_to_lat(test_data_vertex, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 4. h3_to_vertexes() ---------------------------------------------------------

## 4.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_vertexes() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_h3_to_vertexes(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_h3_to_vertexes(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
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
    res <- ddbh3_h3_to_vertexes(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_h3_to_vertexes(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
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
    res <- ddbh3_h3_to_vertexes("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

})


testthat::test_that("unnested result has more rows than nested", {
  ## Unnested (default): one row per vertex
  res_unnested <- ddbh3_h3_to_vertexes(test_data, nested = FALSE) |>
    dplyr::collect()
  ## Nested: one row per cell, vertex column contains a list
  res_nested <- ddbh3_h3_to_vertexes(test_data, nested = TRUE) |>
    dplyr::collect()
  expect_gt(nrow(res_unnested), nrow(res_nested))
})

testthat::test_that("nested result has same number of rows as input", {
  res_nested <- ddbh3_h3_to_vertexes(test_data, nested = TRUE) |>
    dplyr::collect()
  expect_equal(nrow(res_nested), nrow(dplyr::collect(test_data)))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_h3_to_vertexes() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_h3_to_vertexes(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("h3vertex", colnames(res_col))
    expect_type(res_col$h3vertex, "character")
  })

  ## ARGUMENT 2 - NESTED
  testthat::it("nested argument works", {
    ## nested = FALSE returns character column (unnested)
    res_false <- ddbh3_h3_to_vertexes(test_data, nested = FALSE)
    res_false_col <- dplyr::collect(res_false)
    expect_type(res_false_col$h3vertex, "character")
    ## nested = TRUE returns list column
    res_true <- ddbh3_h3_to_vertexes(test_data, nested = TRUE)
    res_true_col <- dplyr::collect(res_true)
    expect_type(res_true_col$h3vertex, "list")
  })

  ## ARGUMENT 3 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_vertexes(test_data, new_column = "res")
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
    expect_message(ddbh3_h3_to_vertexes(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_h3_to_vertexes(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_h3_to_vertexes(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_h3_to_vertexes(
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
    expect_error(ddbh3_h3_to_vertexes(test_data, h3 = NULL))
    expect_error(ddbh3_h3_to_vertexes(test_data, h3 = TRUE))
    expect_error(ddbh3_h3_to_vertexes(test_data, h3 = 2))
  })

  it("requires nested argument as logical", {
    expect_error(ddbh3_h3_to_vertexes(test_data, nested = NULL))
    expect_error(ddbh3_h3_to_vertexes(test_data, nested = "yes"))
    expect_error(ddbh3_h3_to_vertexes(test_data, nested = 1))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_h3_to_vertexes(test_data, new_column = NULL))
    expect_error(ddbh3_h3_to_vertexes(test_data, new_column = FALSE))
    expect_error(ddbh3_h3_to_vertexes(test_data, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_h3_to_vertexes(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_h3_to_vertexes(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_h3_to_vertexes(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_h3_to_vertexes(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_h3_to_vertexes(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_h3_to_vertexes(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})




# 5. vertex_to_spatial() ---------------------------------------------------------

## 5.1. Input data in different formats ----------

testthat::describe("ddbh3_vertex_to_spatial() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {

    ## Check nested
    res <- ddbh3_vertex_to_spatial(test_data_nested)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "MULTIPOINT"
    )

    ## Check unnested
    res <- ddbh3_vertex_to_spatial(test_data_vertex)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "POINT"
    )
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {

    ## Check nested
    test_data_df <- dplyr::collect(test_data_nested)
    res <- ddbh3_vertex_to_spatial(test_data_df)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "MULTIPOINT"
    )

    ## Check unnested
    test_data_df <- dplyr::collect(test_data_vertex)
    res <- ddbh3_vertex_to_spatial(test_data_df)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "POINT"
    )
  })

  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    
    ## Check nested
    ## Convert to sf
    test_data_sf <- test_data_nested |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Apply operation
    res <- ddbh3_vertex_to_spatial(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "MULTIPOINT"
    )

    ## Check unnested
    ## Convert to sf
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Apply operation
    res <- ddbh3_vertex_to_spatial(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
    expect_all_equal(
      duckspatial::ddbs_geometry_type(res_col) |> as.character(),
      "POINT"
    )
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data_vertex |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_vertex_to_spatial(test_data_ddbs)
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
    test_data_sf <- test_data_vertex |>
      dplyr::collect() |>
      sf::st_as_sf(
        coords = c("lon", "lat"),
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_vertex_to_spatial("sf_pts", conn = conn_test)
    ## Check class
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

})


testthat::test_that("unnested input returns one point per row", {
  ## Use flat vertex data (not nested)
  res <- ddbh3_vertex_to_spatial(test_data_vertex)
  res_col <- dplyr::collect(res)
  ## Same number of rows as input
  expect_equal(nrow(res_col), nrow(dplyr::collect(test_data_vertex)))
  ## Geometry column present
  expect_in("geometry", colnames(res_col))
})

testthat::test_that("nested input returns one multipoint per row", {
  ## Build nested vertex data from h3 cells
  test_data_nested <- ddbh3_h3_to_vertexes(test_data, nested = TRUE)
  res <- ddbh3_vertex_to_spatial(test_data_nested)
  res_col <- dplyr::collect(res)
  ## Same number of rows as original cell input
  expect_equal(nrow(res_col), nrow(dplyr::collect(test_data)))
  ## Geometry column present
  expect_in("geometry", colnames(res_col))
})


## 5.2. Arguments work ------------

testthat::describe("ddbh3_vertex_to_spatial() arguments work", {

  ## ARGUMENT 1 - H3VERTEX
  testthat::it("h3vertex argument works", {
    ## Rename h3vertex column
    test_data_mod <- test_data_vertex |>
      dplyr::rename(vertex = h3vertex)
    ## Apply operation with new h3vertex column name
    res <- ddbh3_vertex_to_spatial(test_data_mod, h3vertex = "vertex")
    ## Check class and geometry
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("geometry", colnames(res_col))
  })

  ## ARGUMENT 2 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_vertex_to_spatial(
      dplyr::collect(test_data_vertex),
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_vertex_to_spatial(
      dplyr::collect(test_data_vertex),
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_vertex_to_spatial(
      dplyr::collect(test_data_vertex),
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_vertex_to_spatial(
      dplyr::collect(test_data_vertex),
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 5.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3vertex strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data_vertex))

  ## Tests
  it("requires h3vertex argument as character", {
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, h3vertex = NULL))
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, h3vertex = TRUE))
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, h3vertex = 2))
  })

  it("requires connection when using table names", {
    expect_error(ddbh3_vertex_to_spatial("test_data_tbl", conn = NULL))
  })

  it("validates x argument type", {
    expect_error(ddbh3_vertex_to_spatial(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_vertex_to_spatial(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_vertex_to_spatial(test_data_vertex, conn = conn_test, name = c('banana', 'banana')))
  })

})
