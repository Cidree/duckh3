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
if (FALSE) { # \dontrun{
# load packages
library(duckspatial)
library(duckh3)

# create a duckdb database in memory
conn <- ddbh3_create_conn(dbdir = "memory")

# create a duckdb database in disk
conn <- ddbh3_create_conn(dbdir = "my_database.duckdb")

# create an in-memory connection with 1 thread and 2GB memory limit
conn <- ddbh3_create_conn(threads = 1, memory_limit_gb = 2)
ddbs_stop_conn(conn)
} # }
```
