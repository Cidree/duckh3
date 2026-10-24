# Get the maximum grid disk size for a given distance k

Computes the theoretical maximum number of cells contained within a grid
disk of a specified grid distance `k`.

## Usage

``` r
ddbh3_max_grid_disk_size(k = 1, conn = NULL)
```

## Arguments

- k:

  Integer. The maximum grid distance (k-ring radius).

- conn:

  A DuckDB connection object. If `NULL`, uses or creates the default
  connection.

## Value

An integer scalar representing the maximum number of cells.

## Examples

``` r
library(duckh3)
ddbh3_max_grid_disk_size(k = 2)
#> [1] 19
```
