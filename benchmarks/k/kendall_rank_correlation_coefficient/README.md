# Kendall Rank Correlation Coefficient

Compute Kendall's tau-b for two bounded integer samples, including ties.

## Contract

- Input is `[n, x[0..n), y[0..n)]`, with `2 <= n <= 128`, exact length `1 + 2*n`, and sample values in `[-1,000,000, 1,000,000]`.
- Compare every unordered observation pair. Count concordant and discordant pairs, plus pairs tied in each sample. Return `(concordant - discordant) / sqrt((all_pairs - x_tied_pairs) * (all_pairs - y_tied_pairs))` as binary64.
- If either sample has no variation, or the packed input is malformed or out of range, return `-1e300`.
- The quadratic pair scan is bounded by 8,128 pairs. Integer pair counts are exact in all nine languages; the result uses absolute and relative tolerance `1e-12`.

## Source

- The pinned [TheAlgorithms/R `correlation_analysis.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/biomedical/correlation_analysis.r) obtains Kendall's coefficient from `cor(x, y, method = "kendall")`; its p-value and confidence interval calculations are outside this coefficient contract.
- The R `cor` documentation specifies that ties use Kendall's tau-b: [R `cor` manual](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/cor.html).

## Workload and build

[`workload.json`](workload.json) covers perfect positive and negative order, ties in one or both samples, the two-observation boundary, maximum input length, constant samples, and malformed data.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm kendall_rank_correlation_coefficient --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/k/kendall_rank_correlation_coefficient/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/kendall_rank_correlation_coefficient.c`](../../../c/k/kendall_rank_correlation_coefficient.c) |
| C3 | [`c3/k/kendall_rank_correlation_coefficient.c3`](../../../c3/k/kendall_rank_correlation_coefficient.c3) |
| C++ | [`cpp/k/kendall_rank_correlation_coefficient.cpp`](../../../cpp/k/kendall_rank_correlation_coefficient.cpp) |
| Elisa | [`elisa/k/kendall_rank_correlation_coefficient.elisa`](../../../elisa/k/kendall_rank_correlation_coefficient.elisa) |
| Nim | [`nim/k/kendall_rank_correlation_coefficient.nim`](../../../nim/k/kendall_rank_correlation_coefficient.nim) |
| Odin | [`odin/k/kendall_rank_correlation_coefficient.odin`](../../../odin/k/kendall_rank_correlation_coefficient.odin) |
| Rust | [`rust/k/kendall_rank_correlation_coefficient.rs`](../../../rust/k/kendall_rank_correlation_coefficient.rs) |
| V | [`v/k/kendall_rank_correlation_coefficient.v`](../../../v/k/kendall_rank_correlation_coefficient.v) |
| Zig | [`zig/k/kendall_rank_correlation_coefficient.zig`](../../../zig/k/kendall_rank_correlation_coefficient.zig) |
