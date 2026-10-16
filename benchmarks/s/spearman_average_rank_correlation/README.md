# Spearman Average-Rank Correlation

Compute Spearman's rank correlation by assigning average ranks to ties and applying Pearson correlation to the two rank vectors.

## Contract

- Input is `[n, x[0..n), y[0..n)]`, with `2 <= n <= 128`, exact length `1 + 2*n`, and sample values in `[-1,000,000, 1,000,000]`.
- Equal sample values receive their average 1-based rank. Return the Pearson coefficient of the two rank vectors as binary64.
- A constant rank vector, malformed layout, or out-of-range sample returns `-1e300`.
- Ranking uses a bounded pair scan, so the implementation runs in `O(n²)` time with constant auxiliary storage. Results use absolute and relative tolerance `1e-12`.

## Source

- The pinned [TheAlgorithms/R `correlation_analysis.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/biomedical/correlation_analysis.r) calls `cor(x, y, method = "spearman")`.
- R documents Spearman correlation as Pearson correlation of the rank vectors and averages ranks for ties: [R `cor` manual](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/cor.html), [R `rank` manual](https://stat.ethz.ch/R-manual/R-patched/library/base/html/rank.html).
- This coefficient is distinct from TheAlgorithms/Python's separately benchmarked `spearman_rank_correlation_coefficient`, which applies the rank-difference formula and rounds the output to one decimal; tied inputs can therefore produce different values.

## Workload and build

[`workload.json`](workload.json) includes tied samples that distinguish average-rank Pearson correlation from the rank-difference formula, perfect positive and negative ordering, maximum input length, constant ranks, and malformed data.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm spearman_average_rank_correlation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/spearman_average_rank_correlation/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/spearman_average_rank_correlation.c`](../../../c/s/spearman_average_rank_correlation.c) |
| C3 | [`c3/s/spearman_average_rank_correlation.c3`](../../../c3/s/spearman_average_rank_correlation.c3) |
| C++ | [`cpp/s/spearman_average_rank_correlation.cpp`](../../../cpp/s/spearman_average_rank_correlation.cpp) |
| Elisa | [`elisa/s/spearman_average_rank_correlation.elisa`](../../../elisa/s/spearman_average_rank_correlation.elisa) |
| Nim | [`nim/s/spearman_average_rank_correlation.nim`](../../../nim/s/spearman_average_rank_correlation.nim) |
| Odin | [`odin/s/spearman_average_rank_correlation.odin`](../../../odin/s/spearman_average_rank_correlation.odin) |
| Rust | [`rust/s/spearman_average_rank_correlation.rs`](../../../rust/s/spearman_average_rank_correlation.rs) |
| V | [`v/s/spearman_average_rank_correlation.v`](../../../v/s/spearman_average_rank_correlation.v) |
| Zig | [`zig/s/spearman_average_rank_correlation.zig`](../../../zig/s/spearman_average_rank_correlation.zig) |
