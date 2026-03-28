
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


# 1. is_pentagon() ---------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_is_pentagon() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_is_pentagon(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_is_pentagon(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
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
    res <- ddbh3_is_pentagon(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
  })


  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |> 
      dplyr::collect() |> 
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_is_pentagon(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
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
    res <- ddbh3_is_pentagon("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
  })
  
})


testthat::test_that("pentagon returns true", {
  pentagon_df <- data.frame(h3string = "870800000ffffff")
  res <- ddbh3_is_pentagon(pentagon_df)
  ## Check false
  res_col <- dplyr::collect(res)
  expect_true(res_col$ispentagon)
})

testthat::test_that("hexagon returns false", {
  pentagon_df <- data.frame(h3string = "8ad02dcc1947fff")
  res <- ddbh3_is_pentagon(pentagon_df)
  ## Check false
  res_col <- dplyr::collect(res)
  expect_false(res_col$ispentagon)
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_is_pentagon() arguments work", {
  
  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |> 
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_is_pentagon(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ispentagon", colnames(res_col))
    expect_type(res_col$ispentagon, "logical")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_is_pentagon(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "logical")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_is_pentagon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Apply operation with connection
    expect_no_message(ddbh3_is_pentagon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_is_pentagon(
      dplyr::collect(test_data), 
      new_column = "res",
      conn = conn_test, 
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_is_pentagon(
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
    expect_error(ddbh3_is_pentagon(test_data, h3 = NULL))
    expect_error(ddbh3_is_pentagon(test_data, h3 = TRUE))
    expect_error(ddbh3_is_pentagon(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_is_pentagon(test_data, new_column = NULL))
    expect_error(ddbh3_is_pentagon(test_data, new_column = FALSE))
    expect_error(ddbh3_is_pentagon(test_data, new_column = 25))
  })
  
  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_is_pentagon("test_data_tbl", conn = NULL)))
    )
  })
  
  it("validates x argument type", {
    expect_error(ddbh3_is_pentagon(x = 999))
  })
  
  it("validates conn argument type", {
    expect_error(ddbh3_is_pentagon(test_data, conn = 999))
  })
  
  it("validates overwrite argument type", {
    expect_error(ddbh3_is_pentagon(test_data, overwrite = 999))
  })
  
  it("validates quiet argument type", {
    expect_error(ddbh3_is_pentagon(test_data, quiet = 999))
  })
  
  it("validates table name exists", {
    expect_error(ddbh3_is_pentagon(x = "999", conn = conn_test))
  })
  
  it("requires name to be single character string", {
    expect_error(ddbh3_is_pentagon(test_data, conn = conn_test, name = c('banana', 'banana')))
  })
})
  

# 2. is_h3() ---------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_is_h3() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_is_h3(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_is_h3(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
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
    res <- ddbh3_is_h3(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_is_h3(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
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
    res <- ddbh3_is_h3("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
  })

})


testthat::test_that("valid h3 cell returns true", {
  valid_df <- data.frame(h3string = "8ad02dcc1947fff")
  res <- ddbh3_is_h3(valid_df)
  res_col <- dplyr::collect(res)
  expect_true(res_col$ish3)
})

testthat::test_that("invalid h3 string returns false", {
  invalid_df <- data.frame(h3string = "not_an_h3_string")
  res <- ddbh3_is_h3(invalid_df)
  res_col <- dplyr::collect(res)
  expect_false(res_col$ish3)
})


## 2.2. Arguments work ------------

testthat::describe("ddbh3_is_h3() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_is_h3(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("ish3", colnames(res_col))
    expect_type(res_col$ish3, "logical")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_is_h3(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "logical")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_is_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_is_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_is_h3(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_is_h3(
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
    expect_error(ddbh3_is_h3(test_data, h3 = NULL))
    expect_error(ddbh3_is_h3(test_data, h3 = TRUE))
    expect_error(ddbh3_is_h3(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_is_h3(test_data, new_column = NULL))
    expect_error(ddbh3_is_h3(test_data, new_column = FALSE))
    expect_error(ddbh3_is_h3(test_data, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_is_h3(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_is_h3(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_is_h3(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_is_h3(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_is_h3(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_is_h3(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})


# 3. is_res_class_iii() ---------------------------------------------------------

## 3.1. Input data in different formats ----------

testthat::describe("ddbh3_is_res_class_iii() works in different formats", {

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_is_res_class_iii(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data)
    res <- ddbh3_is_res_class_iii(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
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
    res <- ddbh3_is_res_class_iii(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_is_res_class_iii(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
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
    res <- ddbh3_is_res_class_iii("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
  })

})


testthat::test_that("class III resolution returns true", {
  # Odd resolutions (1, 3, 5, 7, 9, 11, 13, 15) are Class III
  class_iii_df <- data.frame(h3string = "85283473fffffff")
  res <- ddbh3_is_res_class_iii(class_iii_df)
  res_col <- dplyr::collect(res)
  expect_true(res_col$isclassiii)
})

testthat::test_that("class II resolution returns false", {
  # Even resolutions (0, 2, 4, 6, 8, 10, 12, 14) are Class II
  class_ii_df <- data.frame(h3string = "8208000000fffff")
  res <- ddbh3_is_res_class_iii(class_ii_df)
  res_col <- dplyr::collect(res)
  expect_false(res_col$isclassiii)
})


## 3.2. Arguments work ------------

testthat::describe("ddbh3_is_res_class_iii() arguments work", {

  ## ARGUMENT 1 - H3
  testthat::it("h3 argument works", {
    ## Rename h3string column
    test_data_mod <- test_data |>
      dplyr::rename(h3 = h3string)
    ## Apply operation with new h3 column name
    res <- ddbh3_is_res_class_iii(test_data_mod, h3 = "h3")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isclassiii", colnames(res_col))
    expect_type(res_col$isclassiii, "logical")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_is_res_class_iii(test_data, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "logical")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_is_res_class_iii(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_is_res_class_iii(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_is_res_class_iii(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_is_res_class_iii(
      dplyr::collect(test_data),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 3.3. Errors on weird inputs -----------

describe("errors", {

  ## Get h3strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data))

  ## Tests
  it("requires h3 argument as character", {
    expect_error(ddbh3_is_res_class_iii(test_data, h3 = NULL))
    expect_error(ddbh3_is_res_class_iii(test_data, h3 = TRUE))
    expect_error(ddbh3_is_res_class_iii(test_data, h3 = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_is_res_class_iii(test_data, new_column = NULL))
    expect_error(ddbh3_is_res_class_iii(test_data, new_column = FALSE))
    expect_error(ddbh3_is_res_class_iii(test_data, new_column = 25))
  })

  it("requires connection when using table names", {
    expect_warning(
      expect_true(is.na(ddbh3_is_res_class_iii("test_data_tbl", conn = NULL)))
    )
  })

  it("validates x argument type", {
    expect_error(ddbh3_is_res_class_iii(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_is_res_class_iii(test_data, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_is_res_class_iii(test_data, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_is_res_class_iii(test_data, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_is_res_class_iii(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_is_res_class_iii(test_data, conn = conn_test, name = c('banana', 'banana')))
  })

})

# 4. is_vertex() ---------------------------------------------------------

## 4.1. Input data in different formats ----------

testthat::describe("ddbh3_is_vertex() works in different formats", {

  test_data_vertex <- ddbh3_h3_to_vertex(test_data)

  ## FORMAT 1 - TBL_DUCKDB_CONNECTION
  testthat::it("returns the correct data for tbl_duckdb_connection", {
    ## Check class
    res <- ddbh3_is_vertex(test_data_vertex)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
  })

  ## FORMAT 2 - DATA.FRAME
  testthat::it("returns the correct data for data.frame", {
    ## Check class
    test_data_df <- dplyr::collect(test_data_vertex)
    res <- ddbh3_is_vertex(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
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
    res <- ddbh3_is_vertex(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
  })

  ## FORMAT 4 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    ## Convert to duckspatial_df
    test_data_ddbs <- test_data_vertex |>
      dplyr::collect() |>
      duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)
    ## Check class
    res <- ddbh3_is_vertex(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
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
    res <- ddbh3_is_vertex("sf_pts", conn = conn_test)
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
  })

})


testthat::test_that("valid vertex returns true", {
  valid_vertex_df <- data.frame(h3vertex = "2222597fffffffff")
  res <- ddbh3_is_vertex(valid_vertex_df)
  res_col <- dplyr::collect(res)
  expect_true(res_col$isvertex)
})

testthat::test_that("invalid vertex returns false", {
  invalid_vertex_df <- data.frame(h3vertex = "not_a_vertex")
  res <- ddbh3_is_vertex(invalid_vertex_df)
  res_col <- dplyr::collect(res)
  expect_false(res_col$isvertex)
})


## 4.2. Arguments work ------------

testthat::describe("ddbh3_is_vertex() arguments work", {

  test_data_vertex <- ddbh3_h3_to_vertex(test_data)

  ## ARGUMENT 1 - H3VERTEX
  testthat::it("h3vertex argument works", {
    ## Rename h3vertex column
    test_data_mod <- test_data_vertex |>
      dplyr::rename(vertex = h3vertex)
    ## Apply operation with new h3vertex column name
    res <- ddbh3_is_vertex(test_data_mod, h3vertex = "vertex")
    ## Check type
    res_col <- dplyr::collect(res)
    expect_in("isvertex", colnames(res_col))
    expect_type(res_col$isvertex, "logical")
  })

  ## ARGUMENT 2 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_is_vertex(test_data_vertex, new_column = "res")
    expect_true("res" %in% colnames(res))
    res_col <- dplyr::collect(res)
    expect_in("res", colnames(res_col))
    expect_type(res_col$res, "logical")
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    ## Create connection
    conn_test <- ddbh3_create_conn()
    ## Apply operation with connection
    expect_message(ddbh3_is_vertex(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Apply operation with connection, quiet
    expect_no_message(ddbh3_is_vertex(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl2",
      quiet = TRUE
    ))
    ## Doesn't overwrite existing table
    expect_error(ddbh3_is_vertex(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl"
    ))
    ## Overwrites existing table when overwrite = TRUE
    expect_true(ddbh3_is_vertex(
      dplyr::collect(test_data_vertex),
      new_column = "res",
      conn = conn_test,
      name = "test_data_tbl",
      overwrite = TRUE
    ))
  })

})


## 1.3. Errors on weird inputs -----------

describe("errors", {

  test_data_vertex <- ddbh3_h3_to_vertex(test_data)

  ## Get h3vertex strings
  conn_test <- ddbh3_create_conn()
  duckdb::dbWriteTable(conn_test, "test_data_tbl", dplyr::collect(test_data_vertex))

  ## Tests
  it("requires h3vertex argument as character", {
    expect_error(ddbh3_is_vertex(test_data_vertex, h3vertex = NULL))
    expect_error(ddbh3_is_vertex(test_data_vertex, h3vertex = TRUE))
    expect_error(ddbh3_is_vertex(test_data_vertex, h3vertex = 2))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_is_vertex(test_data_vertex, new_column = NULL))
    expect_error(ddbh3_is_vertex(test_data_vertex, new_column = FALSE))
    expect_error(ddbh3_is_vertex(test_data_vertex, new_column = 25))
  })

  it("validates x argument type", {
    expect_error(ddbh3_is_vertex(x = 999))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_is_vertex(test_data_vertex, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_is_vertex(test_data_vertex, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_is_vertex(test_data_vertex, quiet = 999))
  })

  it("validates table name exists", {
    expect_error(ddbh3_is_vertex(x = "999", conn = conn_test))
  })

  it("requires name to be single character string", {
    expect_error(ddbh3_is_vertex(test_data_vertex, conn = conn_test, name = c('banana', 'banana')))
  })

})
