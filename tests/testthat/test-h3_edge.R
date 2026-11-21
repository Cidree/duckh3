
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

## Data with edges
edges_tbl    <- ddbh3_h3_to_edges(test_data)
edges_df     <- dplyr::collect(edges_tbl)
edges_sf     <- ddbh3_h3_to_edges(test_data_sf)
edges_ddbs   <- ddbh3_h3_to_edges(test_data_ddbs)
edges_bigint <- ddbh3_strings_to_bigint(test_data) |>
  ddbh3_h3_to_edges(h3 = "h3bigint")

## Known values (checked directly in DuckDB)
h3_origin    <- "8a1fb46622dffff"
h3_neighbor  <- "8a1fb46622d7fff"
h3_far       <- "8a1fb46622e7fff"  # grid distance 2
h3_pentagon  <- "8009fffffffffff"
h3_edge      <- "16a1fb46622dffff"  # h3_origin -> h3_neighbor
h3_edge_1    <- "11a1fb46622dffff"
h3_edge_1_m  <- 72.88594

pair_tbl <- data.frame(h3start = h3_origin, h3end = h3_neighbor)


## Helper: runs the shared format checks for functions that take `h3edge`
## and add `new_column`
check_edge_formats <- function(fun, new_column, type_check) {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- fun(edges_tbl)
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_in(new_column, colnames(res_col))
    expect_true(type_check(res_col[[new_column]]))
  })

  testthat::it("returns the correct data for data.frame", {
    res <- fun(edges_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in(new_column, colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    res <- fun(edges_sf)
    expect_s3_class(res, "duckspatial_df")
    expect_in(new_column, colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- fun(edges_ddbs)
    expect_s3_class(res, "duckspatial_df")
    expect_in(new_column, colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    duckspatial::ddbs_write_table(conn_test, ddbs_collect(edges_sf), "sf_edges")
    res <- fun("sf_edges", conn = conn_test)
    expect_in(new_column, colnames(dplyr::collect(res)))
  })

  testthat::it("works with UBIGINT edges", {
    res <- fun(edges_bigint) |> dplyr::collect()
    expect_in(new_column, colnames(res))
    expect_false(anyNA(res[[new_column]]))
  })

}


## Helper: shared error checks for functions that take `h3edge`
check_edge_errors <- function(fun) {

  it("requires h3edge argument as character", {
    expect_error(fun(edges_tbl, h3edge = 25))
    expect_error(fun(edges_tbl, h3edge = c("h3edge", "h3string")))
  })

  it("fails on a missing column", {
    expect_error(fun(edges_tbl, h3edge = "not_a_column"))
  })

  it("validates x, conn and name", {
    conn_test <- reset_conn_alt()
    expect_error(fun(x = TRUE))
    expect_error(fun(edges_tbl, conn = 999))
    expect_error(fun(x = "999", conn = conn_test))
    expect_error(fun(edges_df, conn = conn_test, name = c("banana", "banana")))
  })

  it("validates overwrite and quiet", {
    expect_error(fun(edges_tbl, overwrite = 1))
    expect_error(fun(edges_tbl, quiet = 1))
  })

  it("errors on invalid edges in vectorized mode", {
    expect_error(fun(h3_origin), "invalid H3")
  })

}


## Helper: database arguments (name, overwrite, quiet)
check_database_args <- function(fun, x) {
  conn_test <- reset_conn_alt()
  expect_message(fun(x, conn = conn_test, name = "test_tbl"))
  expect_no_message(fun(x, conn = conn_test, name = "test_tbl2", quiet = TRUE))
  expect_error(fun(x, conn = conn_test, name = "test_tbl"))
  expect_true(fun(x, conn = conn_test, name = "test_tbl", overwrite = TRUE))
}


ddbs_collect <- duckspatial::ddbs_collect



# 1. h3_to_edges() -------------------------------------------------------

## 1.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_edges() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    expect_s3_class(edges_tbl, "tbl_duckdb_connection")
    expect_in("h3edge", colnames(edges_df))
    expect_type(edges_df$h3edge, "character")
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_h3_to_edges(test_data_df)
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_in("h3edge", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for sf", {
    expect_s3_class(edges_sf, "duckspatial_df")
    expect_in("h3edge", colnames(dplyr::collect(edges_sf)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    expect_s3_class(edges_ddbs, "duckspatial_df")
    expect_in("h3edge", colnames(dplyr::collect(edges_ddbs)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    duckspatial::ddbs_write_table(conn_test, test_data_sf, "sf_pts")
    res <- ddbh3_h3_to_edges("sf_pts", conn = conn_test)
    expect_in("h3edge", colnames(dplyr::collect(res)))
  })

  testthat::it("works with character vectors", {
    res <- ddbh3_h3_to_edges(h3_origin)
    expect_type(res, "list")
    expect_length(res[[1]], 6)
    expect_in(h3_edge, res[[1]])
  })

})


## 1.2. Correctness ------------

testthat::describe("ddbh3_h3_to_edges() returns correct edges", {

  testthat::it("returns 6 valid edges per hexagon", {
    expect_equal(nrow(edges_df), 6 * n_test)
    res <- ddbh3_is_edge(edges_tbl) |> dplyr::collect()
    expect_true(all(res$isedge))
  })

  testthat::it("returns 5 edges for a pentagon", {
    res <- ddbh3_h3_to_edges(data.frame(h3string = h3_pentagon)) |>
      dplyr::collect()
    expect_equal(nrow(res), 5)
  })

  testthat::it("edges start on the input cell", {
    res <- ddbh3_edge_to_origin(edges_tbl) |> dplyr::collect()
    expect_equal(res$h3origin, res$h3string)
  })

})


## 1.3. Arguments work ------------

testthat::describe("ddbh3_h3_to_edges() arguments work", {

  testthat::it("h3 argument works", {
    res <- test_data |>
      dplyr::rename(h3 = h3string) |>
      ddbh3_h3_to_edges(h3 = "h3") |>
      dplyr::collect()
    expect_equal(nrow(res), 6 * n_test)
  })

  testthat::it("nested argument works", {
    res <- ddbh3_h3_to_edges(test_data, nested = TRUE) |> dplyr::collect()
    expect_equal(nrow(res), n_test)
    expect_type(res$h3edge, "list")
    expect_true(all(lengths(res$h3edge) == 6))
  })

  testthat::it("returns UBIGINT edges for UBIGINT cells", {
    res <- dplyr::collect(edges_bigint)
    expect_s3_class(res$h3edge, "integer64")
  })

  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_edges(test_data, new_column = "edges")
    expect_true("edges" %in% colnames(res))
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_h3_to_edges(test_data_sf, mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_h3_to_edges, test_data_df)
  })

})


## 1.4. Errors on weird inputs -----------

describe("ddbh3_h3_to_edges() errors", {

  it("requires h3 argument as character", {
    expect_error(ddbh3_h3_to_edges(test_data, h3 = 25))
  })

  it("requires nested argument as logical", {
    expect_error(ddbh3_h3_to_edges(test_data, nested = "yes"))
  })

  it("requires new_column argument as character", {
    expect_error(ddbh3_h3_to_edges(test_data, new_column = 25))
  })

  it("validates x, conn and name", {
    conn_test <- reset_conn_alt()
    expect_error(ddbh3_h3_to_edges(x = TRUE))
    expect_error(ddbh3_h3_to_edges(test_data, conn = 999))
    expect_error(ddbh3_h3_to_edges(x = "999", conn = conn_test))
    expect_error(ddbh3_h3_to_edges(test_data_df, conn = conn_test, name = c("banana", "banana")))
  })

  it("errors on invalid cells in vectorized mode", {
    expect_error(ddbh3_h3_to_edges("banana"), "invalid H3")
  })

})



# 2. h3_to_edge() --------------------------------------------------------

## 2.1. Input data in different formats ----------

testthat::describe("ddbh3_h3_to_edge() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_edge_to_destination(edges_tbl) |>
      ddbh3_h3_to_edge(h3end = "h3destination", new_column = "edge2")
    expect_s3_class(res, "tbl_duckdb_connection")
    res_col <- dplyr::collect(res)
    expect_equal(res_col$edge2, res_col$h3edge)
  })

  testthat::it("returns the correct data for data.frame", {
    res <- ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = "h3end")
    expect_s3_class(res, "tbl_duckdb_connection")
    expect_equal(dplyr::collect(res)$h3edge, h3_edge)
  })

  testthat::it("returns the correct data for sf", {
    res <- ddbh3_h3_to_edge(test_data_sf, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3edge", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for duckspatial_df", {
    res <- ddbh3_h3_to_edge(test_data_ddbs, h3end = "h3string")
    expect_s3_class(res, "duckspatial_df")
    expect_in("h3edge", colnames(dplyr::collect(res)))
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    DBI::dbWriteTable(conn_test, "pairs", pair_tbl)
    res <- ddbh3_h3_to_edge("pairs", h3start = "h3start", h3end = "h3end", conn = conn_test)
    expect_equal(dplyr::collect(res)$h3edge, h3_edge)
  })

})


## 2.2. Correctness ------------

testthat::describe("ddbh3_h3_to_edge() returns correct edges", {

  testthat::it("returns NA for cells that are not neighbors", {
    res <- data.frame(h3start = h3_origin, h3end = h3_far) |>
      ddbh3_h3_to_edge(h3start = "h3start", h3end = "h3end") |>
      dplyr::collect()
    expect_true(is.na(res$h3edge))
  })

  testthat::it("returns NA for a cell and itself", {
    res <- ddbh3_h3_to_edge(test_data, h3end = "h3string") |> dplyr::collect()
    expect_true(all(is.na(res$h3edge)))
  })

  testthat::it("works with UBIGINT columns", {
    res <- ddbh3_strings_to_bigint(pair_tbl, h3 = "h3start", new_column = "s") |>
      ddbh3_strings_to_bigint(h3 = "h3end", new_column = "e") |>
      ddbh3_h3_to_edge(h3start = "s", h3end = "e") |>
      ddbh3_bigint_to_strings(h3 = "h3edge", new_column = "h3edge") |>
      dplyr::collect()
    expect_equal(res$h3edge, h3_edge)
  })

})


## 2.3. Arguments work ------------

testthat::describe("ddbh3_h3_to_edge() arguments work", {

  testthat::it("new_column argument works", {
    res <- ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = "h3end", new_column = "e")
    expect_true("e" %in% colnames(res))
  })

  testthat::it("mode argument works", {
    expect_s3_class(ddbh3_h3_to_edge(test_data_sf, h3end = "h3string", mode = "sf"), "sf")
  })

  testthat::it("database arguments work", {
    check_database_args(
      function(x, ...) ddbh3_h3_to_edge(x, h3start = "h3start", h3end = "h3end", ...),
      pair_tbl
    )
  })

})


## 2.4. Errors on weird inputs -----------

describe("ddbh3_h3_to_edge() errors", {

  it("requires h3end", {
    expect_error(ddbh3_h3_to_edge(pair_tbl, h3start = "h3start"))
  })

  it("requires h3start and h3end as character", {
    expect_error(ddbh3_h3_to_edge(pair_tbl, h3start = 1, h3end = "h3end"))
    expect_error(ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = TRUE))
  })

  it("fails on a missing column", {
    expect_error(ddbh3_h3_to_edge(pair_tbl, h3start = "h3start", h3end = "not_a_column"))
  })

  it("requires a table (no vectorized mode)", {
    expect_error(ddbh3_h3_to_edge(h3_origin, h3end = h3_neighbor))
  })

})



# 3. edge_to_origin() ----------------------------------------------------

testthat::describe("ddbh3_edge_to_origin() works in different formats", {
  check_edge_formats(ddbh3_edge_to_origin, "h3origin", is.character)
})

testthat::describe("ddbh3_edge_to_origin() returns correct values", {

  testthat::it("returns a known origin", {
    expect_equal(ddbh3_edge_to_origin(h3_edge), h3_origin)
  })

  testthat::it("h3edge and new_column arguments work", {
    res <- edges_tbl |>
      dplyr::rename(e = h3edge) |>
      ddbh3_edge_to_origin(h3edge = "e", new_column = "o") |>
      dplyr::collect()
    expect_equal(res$o, res$h3string)
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_edge_to_origin, edges_df)
  })

})

describe("ddbh3_edge_to_origin() errors", {
  check_edge_errors(ddbh3_edge_to_origin)
})



# 4. edge_to_destination() -----------------------------------------------

testthat::describe("ddbh3_edge_to_destination() works in different formats", {
  check_edge_formats(ddbh3_edge_to_destination, "h3destination", is.character)
})

testthat::describe("ddbh3_edge_to_destination() returns correct values", {

  testthat::it("returns a known destination", {
    expect_equal(ddbh3_edge_to_destination(h3_edge), h3_neighbor)
  })

  testthat::it("destination is a neighbor of the origin", {
    res <- ddbh3_edge_to_destination(edges_tbl) |>
      ddbh3_is_neighbor(h3end = "h3destination") |>
      dplyr::collect()
    expect_true(all(res$isneighbor))
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_edge_to_destination, edges_df)
  })

})

describe("ddbh3_edge_to_destination() errors", {
  check_edge_errors(ddbh3_edge_to_destination)
})



# 5. edge_to_h3() --------------------------------------------------------

testthat::describe("ddbh3_edge_to_h3() works in different formats", {
  check_edge_formats(ddbh3_edge_to_h3, "h3cells", is.character)
})

testthat::describe("ddbh3_edge_to_h3() returns correct values", {

  testthat::it("returns origin and destination", {
    expect_equal(ddbh3_edge_to_h3(h3_edge)[[1]], c(h3_origin, h3_neighbor))
  })

  testthat::it("unnested returns two rows per edge", {
    res <- ddbh3_edge_to_h3(edges_tbl) |> dplyr::collect()
    expect_equal(nrow(res), 2 * nrow(edges_df))
  })

  testthat::it("nested argument works", {
    res <- ddbh3_edge_to_h3(edges_tbl, nested = TRUE) |> dplyr::collect()
    expect_equal(nrow(res), nrow(edges_df))
    expect_type(res$h3cells, "list")
    expect_true(all(lengths(res$h3cells) == 2))
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_edge_to_h3, edges_df)
  })

})

describe("ddbh3_edge_to_h3() errors", {
  check_edge_errors(ddbh3_edge_to_h3)
  it("requires nested argument as logical", {
    expect_error(ddbh3_edge_to_h3(edges_tbl, nested = "yes"))
  })
})



# 6. reverse_edge() ------------------------------------------------------

testthat::describe("ddbh3_reverse_edge() works in different formats", {
  check_edge_formats(ddbh3_reverse_edge, "h3edge_reversed", is.character)
})

testthat::describe("ddbh3_reverse_edge() returns correct values", {

  testthat::it("swaps origin and destination", {
    res <- ddbh3_reverse_edge(edges_tbl) |>
      ddbh3_edge_to_origin(h3edge = "h3edge_reversed", new_column = "rev_origin") |>
      ddbh3_edge_to_destination(new_column = "destination") |>
      dplyr::collect()
    expect_equal(res$rev_origin, res$destination)
  })

  testthat::it("reversing twice returns the original edge", {
    res <- ddbh3_reverse_edge(edges_tbl) |>
      ddbh3_reverse_edge(h3edge = "h3edge_reversed", new_column = "twice") |>
      dplyr::collect()
    expect_equal(res$twice, res$h3edge)
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_reverse_edge, edges_df)
  })

})

describe("ddbh3_reverse_edge() errors", {
  check_edge_errors(ddbh3_reverse_edge)
})



# 7. get_edge_length() ---------------------------------------------------

testthat::describe("ddbh3_get_edge_length() works in different formats", {
  check_edge_formats(ddbh3_get_edge_length, "edge_length", is.numeric)
})

testthat::describe("ddbh3_get_edge_length() returns correct values", {

  testthat::it("returns a known length", {
    expect_equal(ddbh3_get_edge_length(h3_edge_1), h3_edge_1_m, tolerance = 1e-5)
  })

  testthat::it("unit argument works", {
    res_m    <- ddbh3_get_edge_length(h3_edge_1, unit = "m")
    res_km   <- ddbh3_get_edge_length(h3_edge_1, unit = "km")
    res_rads <- ddbh3_get_edge_length(h3_edge_1, unit = "rads")
    expect_equal(res_km, res_m / 1000)
    expect_true(res_rads > 0 && res_rads < res_km)
  })

  testthat::it("an edge and its reverse have the same length", {
    res <- ddbh3_reverse_edge(edges_tbl) |>
      ddbh3_get_edge_length(new_column = "l1") |>
      ddbh3_get_edge_length(h3edge = "h3edge_reversed", new_column = "l2") |>
      dplyr::collect()
    expect_equal(res$l1, res$l2)
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_get_edge_length, edges_df)
  })

})

describe("ddbh3_get_edge_length() errors", {
  check_edge_errors(ddbh3_get_edge_length)
  it("validates unit", {
    expect_error(ddbh3_get_edge_length(edges_tbl, unit = "ft"), "unit")
    expect_error(ddbh3_get_edge_length(edges_tbl, unit = c("m", "km")))
    expect_error(ddbh3_get_edge_length(edges_tbl, unit = 1))
  })
})



# 8. edge_to_spatial() ---------------------------------------------------

## 8.1. Input data in different formats ----------

testthat::describe("ddbh3_edge_to_spatial() works in different formats", {

  testthat::it("returns the correct data for tbl_duckdb_connection", {
    res <- ddbh3_edge_to_spatial(edges_tbl)
    expect_s3_class(res, "duckspatial_df")
    expect_equal(duckspatial::ddbs_crs(res)$input, "EPSG:4326")
  })

  testthat::it("returns the correct data for data.frame", {
    expect_s3_class(ddbh3_edge_to_spatial(edges_df), "duckspatial_df")
  })

  testthat::it("returns the correct data for sf (replaces the geometry)", {
    res <- ddbh3_edge_to_spatial(edges_sf, mode = "sf")
    expect_s3_class(res, "sf")
    expect_true(all(sf::st_geometry_type(res) == "LINESTRING"))
    expect_equal(nrow(res), 6 * n_test)
  })

  testthat::it("returns the correct data for duckspatial_df", {
    expect_s3_class(ddbh3_edge_to_spatial(edges_ddbs), "duckspatial_df")
  })

  testthat::it("returns the correct data for table", {
    conn_test <- reset_conn_alt()
    duckspatial::ddbs_write_table(conn_test, ddbs_collect(edges_sf), "sf_edges")
    res <- ddbh3_edge_to_spatial("sf_edges", conn = conn_test)
    expect_s3_class(res, "duckspatial_df")
  })

  testthat::it("works with UBIGINT edges", {
    res <- ddbh3_edge_to_spatial(edges_bigint, mode = "sf")
    expect_true(all(sf::st_geometry_type(res) == "LINESTRING"))
  })

  testthat::it("works with character vectors", {
    res <- ddbh3_edge_to_spatial(h3_edge_1)
    expect_length(res, 1)
  })

})


## 8.2. Correctness ------------

testthat::describe("ddbh3_edge_to_spatial() returns correct geometries", {

  testthat::it("lines have 2 points (closing point removed)", {
    res <- ddbh3_edge_to_spatial(edges_tbl, mode = "sf")
    n_pts <- vapply(sf::st_geometry(res), nrow, integer(1))
    expect_true(all(n_pts == 2))
  })

  testthat::it("line endpoints are vertices of the origin cell", {
    res <- ddbh3_edge_to_spatial(data.frame(h3edge = h3_edge_1), mode = "sf")
    hex <- ddbh3_h3_to_spatial(data.frame(h3string = h3_origin), mode = "sf")
    expect_true(sf::st_touches(res, hex, sparse = FALSE)[1, 1])
  })

  testthat::it("works on pentagons", {
    res <- ddbh3_h3_to_edges(data.frame(h3string = h3_pentagon)) |>
      ddbh3_edge_to_spatial(mode = "sf")
    expect_equal(nrow(res), 5)
    expect_true(all(sf::st_geometry_type(res) == "LINESTRING"))
  })

})


## 8.3. Arguments and errors ------------

testthat::describe("ddbh3_edge_to_spatial() arguments work", {

  testthat::it("h3edge argument works", {
    res <- edges_tbl |>
      dplyr::rename(e = h3edge) |>
      ddbh3_edge_to_spatial(h3edge = "e")
    expect_s3_class(res, "duckspatial_df")
  })

  testthat::it("database arguments work", {
    check_database_args(ddbh3_edge_to_spatial, edges_df)
  })

})

describe("ddbh3_edge_to_spatial() errors", {

  check_edge_errors(ddbh3_edge_to_spatial)

  it("errors on nested edges", {
    expect_error(
      ddbh3_edge_to_spatial(ddbh3_h3_to_edges(test_data, nested = TRUE)),
      "nested"
    )
  })

})



# 9. Macros ---------------------------------------------------------------

testthat::describe("edge functions work inside dplyr::mutate()", {

  testthat::it("edge macros return the same as the functions", {
    res <- edges_tbl |>
      dplyr::mutate(
        o   = ddbh3_edge_to_origin(h3edge),
        d   = ddbh3_edge_to_destination(h3edge),
        c   = ddbh3_edge_to_h3(h3edge),
        r   = ddbh3_reverse_edge(h3edge),
        l   = ddbh3_get_edge_length(h3edge),
        lkm = ddbh3_get_edge_length(h3edge, "km"),
        v   = ddbh3_is_edge(h3edge),
        n   = ddbh3_is_neighbor(h3string, d),
        e   = ddbh3_h3_to_edge(h3string, d),
        es  = ddbh3_h3_to_edges(h3string)
      ) |>
      dplyr::collect()

    ref <- ddbh3_edge_to_destination(edges_tbl) |>
      ddbh3_get_edge_length() |>
      ddbh3_reverse_edge() |>
      dplyr::collect()

    expect_equal(res$o, res$h3string)
    expect_equal(res$d, ref$h3destination)
    expect_true(all(lengths(res$c) == 2))
    expect_equal(res$r, ref$h3edge_reversed)
    expect_equal(res$l, ref$edge_length)
    expect_equal(res$lkm, ref$edge_length / 1000)
    expect_true(all(res$v))
    expect_true(all(res$n))
    expect_equal(res$e, res$h3edge)
    expect_true(all(lengths(res$es) == 6))
  })

})
