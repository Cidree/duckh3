#' @param x Input data. One of:
#'   \describe{
#'     \item{`duckspatial_df`}{A lazy spatial data frame via dbplyr.}
#'     \item{`sf`}{A spatial data frame.}
#'     \item{`tbl_lazy`}{A lazy data frame from dbplyr.}
#'     \item{`data.frame`}{A standard R data frame.}
#'     \item{character string}{A table or view name in `conn`.}
#'     \item{character vector}{A vector of values to operate on in vectorized mode (requires `conn = NULL`).}
#'   }
