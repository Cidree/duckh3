#' @returns One of the following, depending on the inputs:
#'   \describe{
#'     \item{`tbl_lazy`}{If the output has no geometry, i.e. `x` is not spatial
#'       and the function adds a column. `mode` is ignored in this case.}
#'     \item{`duckspatial_df`}{If the output has geometry (`x` is spatial, e.g. an
#'       `sf` or `duckspatial_df` object, or the function builds geometries, as
#'       `*_to_spatial()` and `ddbh3_h3_to_points()` do) and `mode = "duckspatial"`
#'       (default).}
#'     \item{`sf`}{If the output has geometry and `mode = "sf"`.}
#'     \item{`TRUE` (invisibly)}{If `name` is provided, a table is created in the connection
#'       and `TRUE` is returned invisibly.}
#'     \item{vector}{If `x` is a character vector and `conn = NULL`, the function operates
#'       in vectorized mode, returning a vector of the same length as `x`.}
#'   }
