# Create a DuckDB connection with spatial and h3 extensions

It creates a DuckDB connection, and then it installs and loads the
spatial and h3 extensions

## Usage

``` r
ddbh3_create_conn(
  dbdir = "memory",
  threads = NULL,
  memory_limit_gb = NULL,
  bigint = "integer64",
  ...
)
```

## Arguments

- dbdir:

  String. Either "tempdir", "memory", or file path with .duckdb or .db
  extension. Defaults to "memory".

- threads:

  Integer. Number of threads to use. If `NULL` (default), the setting is
  not changed, and DuckDB engine will use all available cores it detects
  (warning, on some shared HPC nodes the detected number of cores might
  be total number of cores on the node, not the per-job allocation).

- memory_limit_gb:

  Numeric. Memory limit in GB. If `NULL` (default), the setting is not
  changed, and DuckDB engine will use 80% of available operating system
  memory it detects (warning, on some shared HPC nodes the detected
  memory might be the full node memory, not the per-job allocation).

- bigint:

  String. How to handle 64-bit integers. One of "integer64" or "numeric"

- ...:

  Other parameters passed to
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

## Value

A `duckdb_connection`

## Examples

``` r
# \donttest{
# load packages
library(duckspatial)
#> duckspatial 1.2.1 attached
#> * Compatible with DuckDB >= v1.5.4.2
#> 
#> Default output has changed on v1.0.0:
#>   duckspatial now returns lazy `duckspatial_df` (dbplyr) objects
#>   instead of `sf` objects.
#> 
#> To restore the previous behaviour:
#>   ddbs_options(mode = 'sf')
library(duckh3)

# create a duckdb database in memory
conn <- ddbh3_create_conn(dbdir = "memory", threads = 1)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpjxdHki/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.

# create an in-memory connection with 1 thread and 2GB memory limit
conn <- ddbh3_create_conn(threads = 1, memory_limit_gb = 2)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpjxdHki/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.

# Create a persistent database in disk
# conn <- ddbh3_create_conn(dbdir = "my_database.duckdb")

ddbs_stop_conn(conn)
# }
```
