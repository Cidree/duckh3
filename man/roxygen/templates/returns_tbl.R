#' @returns One of the following, depending on the inputs:
#'   \describe{
#'     \item{`tbl_lazy`}{If `x` is not spatial.}
#'     \item{`duckspatial_df`}{If `x` is spatial (e.g. an `sf` or `duckspatial_df` object).}
#'     \item{`TRUE` (invisibly)}{If `name` is provided, a table is created in the connection
#'       and `TRUE` is returned invisibly.}
#'     \item{vector}{If `x` is a character vector and `conn = NULL`, the function operates
#'       in vectorized mode, returning a vector of the same length as `x`.}
#'   }
