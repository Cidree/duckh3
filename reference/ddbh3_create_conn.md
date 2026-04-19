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
# load packages
library(duckspatial)
#> duckspatial 1.0.0 attached
#> * Compatible with DuckDB v1.5.1
#> * This release introduces breaking changes
#> * See full release notes for migration guidance
#> 
#> Default output has changed:
#>   duckspatial now returns lazy `duckspatial_df` (dbplyr) objects
#>   instead of `sf` objects.
#> 
#> To restore the previous behaviour:
#>   ddbs_options(duckspatial.mode = 'sf')
library(duckh3)

# create a duckdb database in memory
conn <- ddbh3_create_conn(dbdir = "memory")

# create an in-memory connection with 1 thread and 2GB memory limit
conn <- ddbh3_create_conn(threads = 1, memory_limit_gb = 2)

# Create a persistent database in disk
# conn <- ddbh3_create_conn(dbdir = "my_database.duckdb")

ddbs_stop_conn(conn)
```
