

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


# 1. h3_to_lon() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_lon() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_h3_to_lon(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_h3_to_lon(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
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
    res <- ddbh3_h3_to_lon(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_h3_to_lon(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
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
    res <- ddbh3_h3_to_lon("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <-duckspatial::ddbs_collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
  })
  
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_h3_to_lon() arguments work", {
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_h3_to_lon(test_data_mod, h3 = "h3")
    ## Checks
    expect_true("lon_1" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lon, res_col$lon_1, tolerance = 0.0001)
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_lon(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lon, res_col$res, tolerance = 0.0001)
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_h3_to_lon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_h3_to_lon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_h3_to_lon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_h3_to_lon(
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
    expect_error(ddbh3_h3_to_lon(test_data, h3 = NULL))
    expect_error(ddbh3_h3_to_lon(test_data, h3 = TRUE))
    expect_error(ddbh3_h3_to_lon(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_h3_to_lon(test_data, new_column = NULL))
    expect_error(ddbh3_h3_to_lon(test_data, new_column = FALSE))
    expect_error(ddbh3_h3_to_lon(test_data, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_h3_to_lon("test_data_tbl", conn = NULL)))
    )
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_h3_to_lon(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_h3_to_lon(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_h3_to_lon(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_h3_to_lon(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_h3_to_lon(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_h3_to_lon(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})
  


# 2. h3_to_lat() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_lat() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_h3_to_lat(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_h3_to_lat(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check resolution is the same as created
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
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
    res <- ddbh3_h3_to_lat(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_h3_to_lat(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <- duckspatial::ddbs_collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
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
    res <- ddbh3_h3_to_lat("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
    ## Check resolution is the same as created
    res_col <-duckspatial::ddbs_collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
  })
  
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_h3_to_lat() arguments work", {
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_h3_to_lat(test_data_mod, h3 = "h3")
    ## Checks
    expect_true("lat_1" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lat, res_col$lat_1, tolerance = 0.0001)
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_lat(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_equal(res_col$lat, res_col$res, tolerance = 0.0001)
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_h3_to_lat(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_h3_to_lat(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_h3_to_lat(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_h3_to_lat(
      dplyr::collect(test_data), 
      new_column = "res",
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
  it("requires h3 argument as character", {
    expect_error(ddbh3_h3_to_lat(test_data, h3 = NULL))
    expect_error(ddbh3_h3_to_lat(test_data, h3 = TRUE))
    expect_error(ddbh3_h3_to_lat(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_h3_to_lat(test_data, new_column = NULL))
    expect_error(ddbh3_h3_to_lat(test_data, new_column = FALSE))
    expect_error(ddbh3_h3_to_lat(test_data, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_h3_to_lat("test_data_tbl", conn = NULL)))
    )
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_h3_to_lat(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_h3_to_lat(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_h3_to_lat(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_h3_to_lat(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_h3_to_lat(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_h3_to_lat(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})



# 3. h3_to_bigint --------------------------------------------------------

## 3.1. Input data in different formats ----------

testthat::describe("ddbh3_strings_to_bigint() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_strings_to_bigint(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check data type
    res_col <- dplyr::collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_strings_to_bigint(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check data type
    res_col <- dplyr::collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
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
    res <- ddbh3_strings_to_bigint(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <- duckspatial::ddbs_collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_strings_to_bigint(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <- duckspatial::ddbs_collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
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
    res <- ddbh3_strings_to_bigint("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <-duckspatial::ddbs_collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
  })
  
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_strings_to_bigint() arguments work", {
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_strings_to_bigint(test_data_mod, h3 = "h3")
    ## Checks
    expect_true("h3bigint" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_s3_class(res_col$h3bigint, "integer64")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_strings_to_bigint(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_s3_class(res_col$res, "integer64")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_strings_to_bigint(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_strings_to_bigint(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_strings_to_bigint(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_strings_to_bigint(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl",
      overwrite = TRUE
    ))

  })

  testthat::it("returns numeric", {
    ## Create a conn
    conn_test <- ddbh3_create_conn(bigint = "numeric")
    ## Check class
    res <- ddbh3_strings_to_bigint(dplyr::collect(test_data), conn = conn_test)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check data type
    res_col <- dplyr::collect(res)
    expect_type(res_col$h3bigint, "double")
    expect_false(inherits(res_col$h3bigint, "integer64"))
  })
  
})

## 2.3. Errors on weird inputs -----------


describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))
    
  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_strings_to_bigint(test_data, h3 = NULL))
    expect_error(ddbh3_strings_to_bigint(test_data, h3 = TRUE))
    expect_error(ddbh3_strings_to_bigint(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_strings_to_bigint(test_data, new_column = NULL))
    expect_error(ddbh3_strings_to_bigint(test_data, new_column = FALSE))
    expect_error(ddbh3_strings_to_bigint(test_data, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_strings_to_bigint("test_data_tbl", conn = NULL)))
    )
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_strings_to_bigint(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_strings_to_bigint(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_strings_to_bigint(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_strings_to_bigint(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_strings_to_bigint(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_strings_to_bigint(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})


# 4. bigint_to_h3 --------------------------------------------------------

## 4.1. Input data in different formats ----------

testthat::describe("ddbh3_bigint_to_strings() works in different formats", {

  test_data_bigint <- ddbh3_strings_to_bigint(test_data) |> 
    dplyr::select(-h3string)

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_bigint_to_strings(test_data_bigint)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check data type
    res_col <- dplyr::collect(res)
    expect_type(res_col$h3string, "character")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_bigint_df <- dplyr::collect(test_data_bigint)
    res <- ddbh3_bigint_to_strings(test_data_bigint_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check data type
    res_col <- dplyr::collect(res)
    expect_type(res_col$h3string, "character")
  })


  ## FORMAT 3 - SF
  testthat::it("returns the correct data for sf", {
    ## Convert to sf
    test_data_bigint_sf <- test_data_bigint |> 
      dplyr::collect() |> 
      sf::st_as_sf(
        coords = c("lon", "lat"), 
        crs = 4326,
        remove = FALSE
      )
    ## Check class
    res <- ddbh3_bigint_to_strings(test_data_bigint_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <- duckspatial::ddbs_collect(res)
    expect_type(res_col$h3string, "character")
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_bigint_ddbs <- test_data_bigint |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_bigint_to_strings(test_data_bigint_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <- duckspatial::ddbs_collect(res)
    expect_type(res_col$h3string, "character")
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
    test_data_bigint_sf <- test_data_bigint |> 
      dplyr::collect() |> 
      sf::st_as_sf(
        coords = c("lon", "lat"), 
        crs = 4326,
        remove = FALSE
      )
    ## Store table in connection
    duckspatial::ddbs_write_table(conn_test, test_data_bigint_sf, "sf_pts")
    ## Apply operation
    res <- ddbh3_bigint_to_strings("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
    ## Check data type
    res_col <-duckspatial::ddbs_collect(res)
    expect_type(res_col$h3string, "character")
  })
  
})


## 4.2. Arguments work ------------

testthat::describe("ddbh3_bigint_to_strings() arguments work", {

  test_data_bigint <- ddbh3_strings_to_bigint(test_data) |> 
    dplyr::select(-h3string)
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_bigint_mod <- test_data_bigint |> 
      dplyr::rename(h3 = h3bigint)
    ## Apply operation with new h3 column name
    res <- ddbh3_bigint_to_strings(test_data_bigint_mod, h3 = "h3")
    ## Checks
    expect_true("h3string" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_type(res_col$h3string, "character")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_bigint_to_strings(test_data_bigint, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_type(res_col$res, "character")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_bigint_to_strings(
      dplyr::collect(test_data_bigint), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_bigint_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_bigint_to_strings(
      dplyr::collect(test_data_bigint), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_bigint_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_bigint_to_strings(
      dplyr::collect(test_data_bigint), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_bigint_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_bigint_to_strings(
      dplyr::collect(test_data_bigint), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_bigint_tbl",
      overwrite = TRUE
    ))

  })
  
})

## 4.3. Errors on weird inputs -----------


describe("errors", {

  ## Create data
  test_data_bigint <- ddbh3_strings_to_bigint(test_data) |> 
    dplyr::select(-h3string)

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_bigint_tbl", dplyr::collect(test_data_bigint))
    
  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, h3 = NULL))
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, h3 = TRUE))
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, new_column = NULL))
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, new_column = FALSE))
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_error(ddbh3_bigint_to_strings("test_data_bigint_tbl", conn = NULL))
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_bigint_to_strings(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_bigint_to_strings(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_bigint_to_strings(test_data_bigint, conn = conn_test, name = c('banana', 'banana')))
  })
})



# 5. h3_to_spatial -------------------------------------------------------

## 5.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_spatial() works in different formats", {

  test_data_bigint <- ddbh3_strings_to_bigint(test_data) |> 
    dplyr::select(-h3string)

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_h3_to_spatial(test_data)
    expect_s3_class(res, "duckspatial_df")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_h3_to_spatial(test_data_df)
    expect_s3_class(res, "duckspatial_df")
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
    res <- ddbh3_h3_to_spatial(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_h3_to_spatial(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
  })


  ## FORMAT 5 - TABLE IN DUCKDB
  testthat::it("returns the correct resolution for table", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Convert to duckspatial_df
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
    res <- ddbh3_h3_to_spatial("sf_pts", conn = conn_test)
    ## Check
    expect_s3_class(res, "duckspatial_df")
  })

  testthat::it("works for bigint/strings", {
    ## Convert to spatial
    res1 <- ddbh3_h3_to_spatial(test_data_bigint, h3 = "h3bigint")
    res2 <- ddbh3_h3_to_spatial(test_data)
    ## Check class
    expect_s3_class(res1, "duckspatial_df")
    expect_s3_class(res2, "duckspatial_df")
    ## Check they are the same
    geom1 <- duckspatial::ddbs_collect(res1) |> 
      dplyr::pull(geometry)

    geom2 <- duckspatial::ddbs_collect(res2) |> 
      dplyr::pull(geometry)

    expect_equal(geom1, geom2)

  })
  
})


## 5.2. Arguments work ------------

testthat::describe("ddbh3_h3_to_spatial() arguments work", {
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_h3_to_spatial(test_data_mod, h3 = "h3")
    ## Checks
    expect_s3_class(res, "duckspatial_df")
  })

  ## ARGUMENT 2 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_h3_to_spatial(
      dplyr::collect(test_data),
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_h3_to_spatial(
      dplyr::collect(test_data), 
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_h3_to_spatial(
      dplyr::collect(test_data), 
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_h3_to_spatial(
      dplyr::collect(test_data), 
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
    expect_error(ddbh3_h3_to_spatial(test_data, h3 = NULL))
    expect_error(ddbh3_h3_to_spatial(test_data, h3 = TRUE))
    expect_error(ddbh3_h3_to_spatial(test_data, h3 = 2))
  })
  
  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_h3_to_spatial("test_data_tbl", conn = NULL)))
    )
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_h3_to_spatial(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_h3_to_spatial(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_h3_to_spatial(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_h3_to_spatial(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_h3_to_spatial(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_h3_to_spatial(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})
