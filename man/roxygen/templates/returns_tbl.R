#' @returns A `tbl_lazy` if `x` is not spatial, or a `duckspatial_df` if `x`
#' is spatial (e.g. `sf` or `duckspatial_df`). Alternatively, it creates a table in the connection
#' if \code{name} is provided, and returns \code{TRUE} invisibly.
