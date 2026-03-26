

# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")

## create duckdb connection
conn_test <- duckh3::ddbh3_create_conn()

## Load example data
points_tbl <- read.csv(
  system.file("extdata/example_pts.csv", package = "duckh3")
)


# 1. ddbs_get_resolution() -----------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_get_resolution() works in different formats", {

  ## Get h3strings
  test_data <- ddbh3_lonlat_to_h3(points_tbl, resolution = 10)

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct resolution for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_get_resolution(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_all_equal(res_col$h3resolution, 10)
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct resolution for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_get_resolution(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_all_equal(res_col$h3resolution, 10)
  })


  ## FORMAT 3 - SF
  testthat::it("returns the correct resolution for sf", {
    ## Convert to sf
    test_data_sf <- test_data |> 
      dplyr::collect() |> 
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_resolution(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_all_equal(res_col$h3resolution, 10)
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct resolution for sf", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_get_resolution(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_all_equal(res_col$h3resolution, 10)
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for sf", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
    test_data_sf <- test_data |> 
      dplyr::collect() |> 
      sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_get_resolution("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <-duckspatial::ddbs_collect(res)
    expect_all_equal(res_col$h3resolution, 10)
  })
  
  
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_get_resolution() arguments work", {
  
  ## Get h3strings
  test_data <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_get_resolution(test_data_mod, h3 = "h3")
    ## Checks
    expect_true("h3resolution" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_all_equal(res_col$h3resolution, 8)
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_get_resolution(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_all_equal(res_col$res, 8)
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_get_resolution(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_get_resolution(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_get_resolution(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_get_resolution(
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
  test_data <- ddbh3_lonlat_to_h3(points_tbl, resolution = 8)
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))
    
  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_get_resolution(test_data, h3 = NULL))
    expect_error(ddbh3_get_resolution(test_data, h3 = TRUE))
    expect_error(ddbh3_get_resolution(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_get_resolution(test_data, new_column = NULL))
    expect_error(ddbh3_get_resolution(test_data, new_column = FALSE))
    expect_error(ddbh3_get_resolution(test_data, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_error(ddbh3_get_resolution("test_data_tbl", conn = NULL))
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_get_resolution(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_get_resolution(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_get_resolution(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_get_resolution(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_get_resolution(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_get_resolution(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})
  
