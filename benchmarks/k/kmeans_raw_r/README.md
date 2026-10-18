# Raw R K-Means

This benchmark follows the custom Lloyd clustering routine in the pinned R
source. It uses deterministic initial row indices so each run starts from the
same distinct samples, then repeats nearest-center assignment and coordinate
means until every center is unchanged.

## Contract

- The `i64_array_float64` ABI receives
  `[rows, dimensions, k, iteration_limit, initial_rows..., data..., field, arg0, arg1]`.
  The `k` initial row indices are zero-based. Dataset coordinates follow in
  row-major order, with all dimensions of row 0 first. The input length must be
  exactly `7 + k + rows * dimensions`; the parser accepts up to 144 words to
  detect one trailing word after the largest valid input.
- `rows` is 2 through 32, `dimensions` is 2 through 4, `k` is 1 through
  `min(8, floor(rows / 2))`, and `iteration_limit` is 1 through 64. Initial row
  indices must be distinct and in `[0, rows)`. Each coordinate is an integer
  in `[-64, 64]` and is used as a binary64 value.
- Each iteration computes Euclidean distances from every row to the current
  centers, assigns each row to its nearest center, and updates each center
  coordinate to the mean of its assigned rows. Equal distances go to the
  lowest center index, matching R's first-result `which.min` behavior. Mean
  sums visit rows in ascending input order; distance sums visit dimensions in
  ascending order.
- If any assigned cluster has fewer than two rows, the result is `-1e300`.
  This makes the contract explicit for empty and singleton clusters, for which
  the source's matrix subsetting plus `apply(..., 2, mean)` is not a defined
  finite center update. If all centers do not stabilize within the supplied
  iteration limit, the result is also `-1e300`.
- `field` selects one value from the final result: `0` returns center
  coordinate `[arg0, arg1]`, where `arg0` is a zero-based center and `arg1` a
  dimension; `1` returns the final distance from row `arg0` to center `arg1`;
  `2` returns the zero-based cluster assignment for row `arg0`, and requires
  `arg1 == 0`. A null input pointer or invalid framing, bounds, field, or field
  indices return `-1e300`.
- Results are binary64 and use absolute and relative tolerances of `1e-12`.

## Source semantics and deterministic adapter

The source is pinned at commit
[`f65344fabeea0ae33c1ca321af709447c1a8a4c2`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/clustering_algorithms/kmeans_raw_r.r).

The pinned implementation initializes centers with `sample.int(rows, size=k)`
and then uses Euclidean distance, first-minimum assignment, and per-column
means. The benchmark provides the distinct initial row indices as input and
does not include R's random-number generation. It preserves the sample-without-
replacement initialization domain while making each case reproducible.

The ABI uses zero-based initial-row, center, feature, and sample indices. Each
is translated to R's one-based matrix indexing inside the source adapter. The
R cluster result from `which(cluster.matrix[row,] == 1)` is one-based; the
benchmark subtracts one before returning the selected cluster ID.

The source's convergence bookkeeping appends `TRUE` only when a center did
not move and leaves changed-center positions unassigned. Those missing entries
can make `all(all.true)` return `NA` and stop the R `while` with an error; if no
center positions were assigned, `all(logical(0))` can instead be `TRUE`,
prematurely ending after one update. The benchmark repairs this bookkeeping by
checking every center against its updated value and adds the explicit iteration
limit above.

This source is distinct from the existing [`kmeans`](../../kmeans/README.md)
contract, which uses deterministic evenly spaced initial centers, and from
the unrelated iris plotting scripts.

## Workload and oracle

[`workload.json`](workload.json) covers stable two-cluster and one-cluster
streams, first-center tie assignment, output selectors, empty/singleton
clusters, invalid initial indices, malformed framing, and iteration exhaustion.
The independent oracle is
[`kmeans_raw_r_oracle.py`](../../kmeans_raw_r_oracle.py).

Build and record with the `i64_array_float64` family:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm kmeans_raw_r --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/k/kmeans_raw_r/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm kmeans_raw_r
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kmeans_raw_r.c`](../../../c/k/kmeans_raw_r.c) |
| C3 | [`c3/k/kmeans_raw_r.c3`](../../../c3/k/kmeans_raw_r.c3) |
| C++ | [`cpp/k/kmeans_raw_r.cpp`](../../../cpp/k/kmeans_raw_r.cpp) |
| Elisa | [`elisa/k/kmeans_raw_r.elisa`](../../../elisa/k/kmeans_raw_r.elisa) |
| Nim | [`nim/k/kmeans_raw_r.nim`](../../../nim/k/kmeans_raw_r.nim) |
| Odin | [`odin/k/kmeans_raw_r.odin`](../../../odin/k/kmeans_raw_r.odin) |
| Rust | [`rust/k/kmeans_raw_r.rs`](../../../rust/k/kmeans_raw_r.rs) |
| V | [`v/k/kmeans_raw_r.v`](../../../v/k/kmeans_raw_r.v) |
| Zig | [`zig/k/kmeans_raw_r.zig`](../../../zig/k/kmeans_raw_r.zig) |
