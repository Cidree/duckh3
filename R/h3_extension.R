

#' Create a DuckDB connection with spatial and h3 extensions
#'
#' It creates a DuckDB connection, and then it installs and loads the
#' spatial and h3 extensions
#'
#' @param dbdir String. Either "tempdir", "memory", or file path with .duckdb 
#' or .db extension. Defaults to "memory".
#' @template threads
#' @template memory_limit_gb
#'
#' @returns A `duckdb_connection`
#' @export
#'
#' @examples
#' \dontrun{
#' # load packages
#' library(duckspatial)
#' library(duckh3)
#'
#' # create a duckdb database in memory
#' conn <- ddbh3_create_conn(dbdir = "memory")
#'
#' # create a duckdb database in disk
#' conn <- ddbh3_create_conn(dbdir = "my_database.duckdb")
#'
#' # create an in-memory connection with 1 thread and 2GB memory limit
#' conn <- ddbh3_create_conn(threads = 1, memory_limit_gb = 2)
#' ddbs_stop_conn(conn)
#' }
ddbh3_create_conn <- function(dbdir = "memory", threads = NULL, memory_limit_gb = NULL){

  # Creates a connection with the Spatial extension
  conn <- duckspatial::ddbs_create_conn(
    dbdir = dbdir,
    threads = threads,
    memory_limit_gb = memory_limit_gb
  )
  
  # Checks and installs the h3 extension
  duckspatial::ddbs_install(conn, upgrade = TRUE, quiet = TRUE, extension = "h3", community = TRUE)
  duckspatial::ddbs_load(conn, quiet = TRUE, extension = "h3")

  return(conn)
}




