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

## Same data in other formats
test_data_df <- dplyr::collect(test_data)

test_data_sf <- test_data_df |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)

test_data_ddbs <- test_data_df |>
  duckspatial::ddbs_as_points(coords = c("lon", "lat"), crs = 4326)

test_data_bigint <- ddbh3_strings_to_bigint(test_data)

## Pairs of points (Madrid -> Barcelona, Santiago -> A Coruna)
pairs_df <- data.frame(
  lon1 = c(-3.70, -8.54),
  lat1 = c(40.42, 42.88),
  lon2 = c(2.17, -8.41),
  lat2 = c(41.39, 43.36)
)
pairs_sf <- sf::st_as_sf(pairs_df, coords = c("lon1", "lat1"), crs = 4326, remove = FALSE)

## Known values (checked directly in DuckDB)
h3_cell        <- "8a1fb46622dffff"
h3_cell_m2     <- 13407.83
h3_pentagon    <- "8009fffffffffff"
h3_edge        <- "16a1fb46622dffff"
madrid_bcn_m   <- 504864
area_avg_8_m2  <- 737327.6
edge_avg_8_m   <- 531.414

ddbs_collect <- duckspatial::ddbs_collect

gc_distance <- function(x, ...) {
  ddbh3_great_circle_distance(x, "lon1", "lat1", "lon2", "lat2", ...)
}


## Helper: database arguments (name, overwrite, quiet)
check_database_args <- function(fun, x) {
  conn_test <- reset_conn_alt()
  expect_message(fun(x, conn = conn_test, name = "test_tbl"))
  expect_no_message(fun(x, conn = conn_test, name = "test_tbl2", quiet = TRUE))
  expect_error(fun(x, conn = conn_test, name = "test_tbl"))
  expect_true(fun(x, conn = conn_test, name = "test_tbl", overwrite = TRUE))
}



# 1. get_area() ----------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_get_area() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_get_area(test_data)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("h3area", colnames(res_col))
    expect_type(res_col$h3area, "double")
    expect_true(all(res_col$h3area > 0))
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_get_area(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("h3area", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_get_area(test_data_sf)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3area", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_get_area(test_data_ddbs)
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3area", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_get_area("sf_pts", conn = conn_test)
    expect_in("h3area", colnames(dplyr::collect(res)))
  })

  testthat::it("works with UBIGINT cells", {
    res_bigint <- ddbh3_get_area(test_data_bigint, h3 = "h3bigint") |>
      dplyr::collect()
    res_string <- ddbh3_get_area(test_data) |> dplyr::collect()
    expect_equal(res_bigint$h3area, res_string$h3area)
  })

  testthat::it("returns a sf object with mode = 'sf'", {
    expect_s3_class(ddbh3_get_area(test_data_sf, mode = "sf"), "sf")
  })

})


## 1.2. Values ----------

testthat::describe("ddbh3_get_area() returns correct values", {

  testthat::it("returns a known area", {
    expect_equal(ddbh3_get_area(h3_cell), h3_cell_m2, tolerance = 1e-5)
  })

  testthat::it("unit argument works", {
    res_m2   <- ddbh3_get_area(h3_cell, unit = "m^2")
    res_km2  <- ddbh3_get_area(h3_cell, unit = "km^2")
    res_rads <- ddbh3_get_area(h3_cell, unit = "rads^2")
    expect_equal(res_km2, res_m2 / 1e6)
    expect_true(res_rads > 0 && res_rads < res_km2)
  })

  testthat::it("works in vectorized mode with several cells", {
    res <- ddbh3_get_area(c(h3_cell, h3_pentagon))
    expect_length(res, 2)
    expect_true(res[2] > res[1])
  })

  testthat::it("is close to the resolution average", {
    res <- ddbh3_get_area(test_data) |> dplyr::collect()
    expect_equal(mean(res$h3area), area_avg_8_m2, tolerance = 0.2)
  })

  testthat::it("works inside mutate", {
    res <- test_data |>
      dplyr::mutate(
        a_m2  = ddbh3_get_area(h3string),
        a_km2 = ddbh3_get_area(h3string, 'km^2')
      ) |>
      dplyr::collect()
    expect_equal(res$a_km2, res$a_m2 / 1e6)
  })

  testthat::it("replaces an existing column", {
    res <- ddbh3_get_area(test_data) |>
      ddbh3_get_area(unit = "km^2") |>
      dplyr::collect()
    expect_equal(sum(grepl("^h3area", colnames(res))), 1)
    expect_true(all(res$h3area < 10))
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_get_area, test_data_df)
  })

})


## 1.3. Errors ----------

describe("ddbh3_get_area() errors", {

  it("requires h3 argument as character", {
    expect_error(ddbh3_get_area(test_data, h3 = 25))
    expect_error(ddbh3_get_area(test_data, h3 = c("h3string", "lon")))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_get_area(test_data, h3 = "not_a_column"))
  })

  it("validates unit", {
    expect_error(ddbh3_get_area(test_data, unit = "m"), "unit")
    expect_error(ddbh3_get_area(test_data, unit = c("m^2", "km^2")))
    expect_error(ddbh3_get_area(test_data, unit = 1))
  })

  it("rejects invalid cells in vectorized mode", {
    expect_error(ddbh3_get_area(h3_edge), "invalid")
    expect_error(ddbh3_get_area("zzz"), "invalid")
  })

  it("validates x, conn and name", {
    conn_test <- reset_conn_alt()
    expect_error(ddbh3_get_area(x = TRUE))
    expect_error(ddbh3_get_area(test_data, conn = 999))
    expect_error(ddbh3_get_area(x = "999", conn = conn_test))
    expect_error(ddbh3_get_area(test_data_df, conn = conn_test, name = c("a", "b")))
  })

  it("validates overwrite and quiet", {
    expect_error(ddbh3_get_area(test_data, overwrite = 1))
    expect_error(ddbh3_get_area(test_data, quiet = 1))
  })

})



# 2. great_circle_distance() ---------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_great_circle_distance() works in different formats", {

  testthat::it("returns the correct data for data.frame", {
    res <- gc_distance(pairs_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in("distance", colnames(res_col))
    expect_type(res_col$distance, "double")
  })

  testthat::it("returns the correct data for sf", {
    res <- gc_distance(pairs_sf)
    expect_s3_class(res, "duckspatial_df")
    expect_in("distance", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "pairs", pairs_df)
    res <- gc_distance("pairs", conn = conn_test)
    expect_in("distance", colnames(dplyr::collect(res)))
  })

})


## 2.2. Values ----------

testthat::describe("ddbh3_great_circle_distance() returns correct values", {

  testthat::it("returns a known distance", {
    res <- gc_distance(pairs_df) |> dplyr::collect()
    expect_equal(res$distance[1], madrid_bcn_m, tolerance = 1e-5)
  })

  testthat::it("unit argument works", {
    res_m    <- gc_distance(pairs_df, unit = "m") |> dplyr::collect()
    res_km   <- gc_distance(pairs_df, unit = "km") |> dplyr::collect()
    res_rads <- gc_distance(pairs_df, unit = "rads") |> dplyr::collect()
    expect_equal(res_km$distance, res_m$distance / 1000)
    expect_true(all(res_rads$distance < res_km$distance))
  })

  testthat::it("is symmetric and zero for the same point", {
    res <- pairs_df |>
      ddbh3_great_circle_distance("lon2", "lat2", "lon1", "lat1", new_column = "d_rev") |>
      ddbh3_great_circle_distance("lon1", "lat1", "lon1", "lat1", new_column = "d_zero") |>
      gc_distance() |>
      dplyr::collect()
    expect_equal(res$distance, res$d_rev)
    expect_equal(res$d_zero, c(0, 0))
  })

  testthat::it("works inside mutate", {
    res <- gc_distance(pairs_df, unit = "km") |>
      dplyr::mutate(d = ddbh3_great_circle_distance(lon1, lat1, lon2, lat2, 'km')) |>
      dplyr::collect()
    expect_equal(res$d, res$distance)
  })

  testthat::it("database arguments work", {
    check_database_args(gc_distance, pairs_df)
  })

})


## 2.3. Errors ----------

describe("ddbh3_great_circle_distance() errors", {

  it("requires the four coordinate columns", {
    expect_error(ddbh3_great_circle_distance(pairs_df, "lon1", "lat1", "lon2"))
    expect_error(ddbh3_great_circle_distance(pairs_df, 1, "lat1", "lon2", "lat2"))
    expect_error(gc_distance(pairs_df |> dplyr::rename(lonx = lon1)))
  })

  it("validates unit", {
    expect_error(gc_distance(pairs_df, unit = "ft"), "unit")
    expect_error(gc_distance(pairs_df, unit = c("m", "km")))
  })

  it("validates overwrite and quiet", {
    expect_error(gc_distance(pairs_df, overwrite = 1))
    expect_error(gc_distance(pairs_df, quiet = 1))
  })

})



# 3. get_hexagon_*_avg() -------------------------------------------------

testthat::describe("ddbh3_get_hexagon_area_avg() and ddbh3_get_hexagon_edge_length_avg() work", {

  testthat::it("return known values", {
    expect_equal(ddbh3_get_hexagon_area_avg(8), area_avg_8_m2, tolerance = 1e-5)
    expect_equal(ddbh3_get_hexagon_edge_length_avg(8), edge_avg_8_m, tolerance = 1e-5)
  })

  testthat::it("unit argument works", {
    expect_equal(
      ddbh3_get_hexagon_area_avg(8, unit = "km^2"),
      ddbh3_get_hexagon_area_avg(8) / 1e6
    )
    expect_equal(
      ddbh3_get_hexagon_edge_length_avg(8, unit = "km"),
      ddbh3_get_hexagon_edge_length_avg(8) / 1000
    )
  })

  testthat::it("are vectorized and keep the order of resolution", {
    res <- ddbh3_get_hexagon_area_avg(c(8, 0, 15))
    expect_length(res, 3)
    expect_equal(res[1], area_avg_8_m2, tolerance = 1e-5)
    res_all <- ddbh3_get_hexagon_edge_length_avg(0:15)
    expect_length(res_all, 16)
    expect_true(all(diff(res_all) < 0))
  })

  testthat::it("work with a user connection", {
    expect_equal(
      ddbh3_get_hexagon_area_avg(8, conn = reset_conn_alt()),
      ddbh3_get_hexagon_area_avg(8)
    )
  })

  testthat::it("work inside mutate", {
    res <- test_data |>
      dplyr::mutate(
        area_avg = ddbh3_get_hexagon_area_avg(ddbh3_get_resolution(h3string)),
        edge_avg = ddbh3_get_hexagon_edge_length_avg(8, 'km')
      ) |>
      dplyr::collect()
    expect_equal(unique(res$area_avg), area_avg_8_m2, tolerance = 1e-5)
    expect_equal(unique(res$edge_avg), edge_avg_8_m / 1000, tolerance = 1e-5)
  })

})

describe("ddbh3_get_hexagon_area_avg() and ddbh3_get_hexagon_edge_length_avg() errors", {

  it("validate resolution", {
    expect_error(ddbh3_get_hexagon_area_avg(16), "resolution")
    expect_error(ddbh3_get_hexagon_area_avg(-1), "resolution")
    expect_error(ddbh3_get_hexagon_area_avg(1.5), "resolution")
    expect_error(ddbh3_get_hexagon_area_avg(NA), "resolution")
    expect_error(ddbh3_get_hexagon_area_avg("8"), "resolution")
    expect_error(ddbh3_get_hexagon_edge_length_avg(numeric(0)), "resolution")
  })

  it("validate unit", {
    expect_error(ddbh3_get_hexagon_area_avg(8, unit = "rads^2"), "unit")
    expect_error(ddbh3_get_hexagon_area_avg(8, unit = "m"), "unit")
    expect_error(ddbh3_get_hexagon_edge_length_avg(8, unit = "rads"), "unit")
  })

})
