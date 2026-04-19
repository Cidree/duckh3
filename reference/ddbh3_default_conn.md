# Get or create default DuckDB connection

Setup the default connection with h3 and spatial extensions installed
and loaded. It will be used internally by the package functions if no
other connection is provided

## Usage

``` r
ddbh3_default_conn(create = TRUE, upgrade_h3 = FALSE, ...)
```

## Arguments

- create:

  Logical. If TRUE and no connection exists, create one. Default is
  TRUE.

- upgrade_h3:

  Logical. If TRUE, will attempt to upgrade the h3 extension

- ...:

  Additional parameters to pass to
  [`duckspatial::ddbs_create_conn()`](https://cidree.github.io/duckspatial/reference/ddbs_create_conn.html)

## Value

Invisibly, the default `duckdb_connection`

## Examples

``` r
# Get or create default connection
```
