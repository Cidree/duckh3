# 0. Set up --------------------------------------------------------------

## skip tests on CRAN because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()
testthat::skip_if_not_installed("duckdb")
testthat::skip_if_not_installed("duckspatial")
testthat::skip_if_not_installed("sf")

## create duckdb connection
conn_test <- duckh3::ddbh3_default_conn()

## Build a small polygon and a small line in EPSG:4326
poly_sf <- sf::st_as_sf(
  sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(-0.5, -0.5), c(0.5, -0.5), c(0.5, 0.5), c(-0.5, 0.5), c(-0.5, -0.5)
    ))),
    crs = 4326
  )
)

line_sf <- sf::st_as_sf(
  sf::st_sfc(
    sf::st_linestring(rbind(c(-0.5, -0.5), c(0.5, 0.5))),
    crs = 4326
  )
)


# 1. polygons_to_h3() ------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_polygons_to_h3() works in different formats", {

  ## FORMAT 1 - SF
  testthat::it("returns the correct data for sf", {
    res <- ddbh3_polygons_to_h3(poly_sf, resolution = 3)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
    expect_type(res_col$h3string, "list")
  })

  ## FORMAT 2 - DUCKSPATIAL_DF
  testthat::it("returns the correct data for duckspatial_df", {
    poly_ddbs <- duckspatial::as_duckspatial_df(poly_sf)
    res <- ddbh3_polygons_to_h3(poly_ddbs, resolution = 3)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
  })

  ## FORMAT 3 - TABLE IN DUCKDB
  testthat::it("returns the correct data for table", {
    conn_test2 <- ddbh3_create_conn()
    duckspatial::ddbs_write_table(conn_test2, poly_sf, "poly_pts")
    res <- ddbh3_polygons_to_h3("poly_pts", resolution = 3, conn = conn_test2)
    expect_s3_class(res, "duckspatial_df")
    res_col <- dplyr::collect(res)
    expect_in("h3string", colnames(res_col))
  })

})

testthat::test_that("returns one row per input feature", {
  res <- ddbh3_polygons_to_h3(poly_sf, resolution = 3) |> dplyr::collect()
  expect_equal(nrow(res), nrow(poly_sf))
})

testthat::test_that("string format returns character list, bigint returns integer64 list", {
  res_string <- ddbh3_polygons_to_h3(poly_sf, resolution = 3, h3_format = "string") |>
    dplyr::collect()
  expect_type(res_string$h3string[[1]], "character")

  res_bigint <- ddbh3_polygons_to_h3(poly_sf, resolution = 3, h3_format = "bigint") |>
    dplyr::collect()
  expect_s3_class(res_bigint$h3string[[1]], "integer64")
})

testthat::test_that("finer resolution returns more cells", {
  res_fine <- ddbh3_polygons_to_h3(poly_sf, resolution = 5) |> dplyr::collect()
  res_coarse <- ddbh3_polygons_to_h3(poly_sf, resolution = 2) |> dplyr::collect()
  expect_gt(length(res_fine$h3string[[1]]), length(res_coarse$h3string[[1]]))
})

testthat::test_that("rejects non-EPSG:4326 input", {
  poly_3857 <- duckspatial::ddbs_transform(poly_sf, 3857)
  expect_error(ddbh3_polygons_to_h3(poly_3857, resolution = 3))
})

testthat::test_that("rejects non-polygon geometry", {
  expect_error(ddbh3_polygons_to_h3(line_sf, resolution = 3))
})


## 1.2. Arguments work ------------

testthat::describe("ddbh3_polygons_to_h3() arguments work", {

  ## ARGUMENT 1 - NEW_COLUMN
  testthat::it("new_column argument works", {
    res <- ddbh3_polygons_to_h3(poly_sf, resolution = 3, new_column = "cells")
    expect_true("cells" %in% colnames(res))
  })

  ## ARGUMENT 2 - CONTAINMENT
  testthat::it("containment argument works", {
    for (cont in c("overlap", "full", "center", "overlap_bbox")) {
      res <- ddbh3_polygons_to_h3(poly_sf, resolution = 3, containment = cont) |>
        dplyr::collect()
      expect_true(is.list(res$h3string))
    }
  })

  ## ARGUMENT 3 - DATABASE ARGUMENTS
  testthat::it("database arguments work", {
    conn_test2 <- ddbh3_create_conn()
    expect_message(ddbh3_polygons_to_h3(
      poly_sf,
      resolution = 3,
      conn = conn_test2,
      name = "poly_h3_tbl"
    ))
    expect_no_message(ddbh3_polygons_to_h3(
      poly_sf,
      resolution = 3,
      conn = conn_test2,
      name = "poly_h3_tbl2",
      quiet = TRUE
    ))
    expect_error(ddbh3_polygons_to_h3(
      poly_sf,
      resolution = 3,
      conn = conn_test2,
      name = "poly_h3_tbl"
    ))
    expect_true(ddbh3_polygons_to_h3(
      poly_sf,
      resolution = 3,
      conn = conn_test2,
      name = "poly_h3_tbl",
      overwrite = TRUE
    ))
  })

})


## 1.3. Errors on weird inputs -----------

describe("errors", {

  it("requires resolution to be an integer scalar", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = NULL))
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = "a"))
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 1.5))
  })

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = -1))
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 16))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, new_column = NULL))
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, new_column = 25))
  })

  it("requires h3_format to be a valid option", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, h3_format = "invalid"))
  })

  it("requires containment to be a valid option", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, containment = "invalid"))
  })

  it("validates x argument type", {
    expect_error(ddbh3_polygons_to_h3(x = 999, resolution = 3))
  })

  it("validates conn argument type", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, conn = 999))
  })

  it("validates overwrite argument type", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, overwrite = 999))
  })

  it("validates quiet argument type", {
    expect_error(ddbh3_polygons_to_h3(poly_sf, resolution = 3, quiet = 999))
  })

})


# 2. polygons_to_spatial() --------------------------------------------------

testthat::test_that("returns one row per intersecting cell (POLYGON geometry)", {
  res <- ddbh3_polygons_to_spatial(poly_sf, resolution = 3) |> dplyr::collect()
  expect_true(nrow(res) >= 1)
  expect_s3_class(res$x, "sfc_POLYGON")
})

testthat::test_that("geometry column contains polygons", {
  res <- ddbh3_polygons_to_spatial(poly_sf, resolution = 3)
  expect_true(all(duckspatial::ddbs_geometry_type(res) == "POLYGON"))
})

testthat::test_that("finer resolution returns more rows", {
  res_fine <- ddbh3_polygons_to_spatial(poly_sf, resolution = 5) |> dplyr::collect()
  res_coarse <- ddbh3_polygons_to_spatial(poly_sf, resolution = 2) |> dplyr::collect()
  expect_gt(nrow(res_fine), nrow(res_coarse))
})

describe("errors", {

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_polygons_to_spatial(poly_sf, resolution = -1))
    expect_error(ddbh3_polygons_to_spatial(poly_sf, resolution = 16))
  })

  it("rejects non-polygon geometry", {
    expect_error(ddbh3_polygons_to_spatial(line_sf, resolution = 3))
  })

  it("validates x argument type", {
    expect_error(ddbh3_polygons_to_spatial(x = 999, resolution = 3))
  })

})


# 3. lines_to_h3() -----------------------------------------------------------

testthat::test_that("returns one row per input feature", {
  res <- ddbh3_lines_to_h3(line_sf, resolution = 3) |> dplyr::collect()
  expect_equal(nrow(res), nrow(line_sf))
  expect_true(length(res$h3string[[1]]) >= 1)
})

testthat::test_that("string format returns character list, bigint returns integer64 list", {
  res_string <- ddbh3_lines_to_h3(line_sf, resolution = 3, h3_format = "string") |>
    dplyr::collect()
  expect_type(res_string$h3string[[1]], "character")

  res_bigint <- ddbh3_lines_to_h3(line_sf, resolution = 3, h3_format = "bigint") |>
    dplyr::collect()
  expect_s3_class(res_bigint$h3string[[1]], "integer64")
})

testthat::test_that("larger buffer_scale never loses cells found with the default", {
  res_default <- ddbh3_lines_to_h3(line_sf, resolution = 4) |> dplyr::collect()
  res_bigger  <- ddbh3_lines_to_h3(line_sf, resolution = 4, buffer_scale = 3) |> dplyr::collect()
  expect_true(all(res_default$h3string[[1]] %in% res_bigger$h3string[[1]]))
})

describe("errors", {

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_lines_to_h3(line_sf, resolution = -1))
    expect_error(ddbh3_lines_to_h3(line_sf, resolution = 16))
  })

  it("rejects non-line geometry", {
    expect_error(ddbh3_lines_to_h3(poly_sf, resolution = 3))
  })

  it("validates x argument type", {
    expect_error(ddbh3_lines_to_h3(x = 999, resolution = 3))
  })

})


# 4. lines_to_spatial() -------------------------------------------------------

testthat::test_that("returns one row per intersecting cell (LINESTRING geometry)", {
  res <- ddbh3_lines_to_spatial(line_sf, resolution = 3) |> dplyr::collect()
  expect_true(nrow(res) >= 1)
  expect_s3_class(res$x, "sfc_POLYGON")
})

testthat::test_that("every returned cell truly intersects the original line", {
  res <- ddbh3_lines_to_spatial(line_sf, resolution = 4)
  ## re-derive intersection with the source line; should keep every row
  intersects <- duckspatial::ddbs_intersects(res, line_sf) |> dplyr::collect()
  expect_equal(nrow(intersects), nrow(dplyr::collect(res)))
})

describe("errors", {

  it("requires resolution to be in the range 0-15", {
    expect_error(ddbh3_lines_to_spatial(line_sf, resolution = -1))
    expect_error(ddbh3_lines_to_spatial(line_sf, resolution = 16))
  })

  it("rejects non-line geometry", {
    expect_error(ddbh3_lines_to_spatial(poly_sf, resolution = 3))
  })

  it("validates x argument type", {
    expect_error(ddbh3_lines_to_spatial(x = 999, resolution = 3))
  })

})
