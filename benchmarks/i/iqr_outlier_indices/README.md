# IQR Outlier Indices

Find values outside the strict 1.5-IQR fences using the pinned R source's default quantiles.

## Contract

- Input is a nonempty array of 1 to 62 signed integers in `[-1,000,000, 1,000,000]`.
- Sort a copy of the values and compute Q1 and Q3 with R's default type-7 sample quantile interpolation. The lower and upper fences are `Q1 - 1.5*(Q3-Q1)` and `Q3 + 1.5*(Q3-Q1)`; the source selects values strictly below or above those fences.
- The source returns 1-based outlier indices. To preserve the complete index set in the scalar ABI, bit `i` represents source index `i+1`. The 62-element limit keeps every possible mask within a positive signed 64-bit result.
- Malformed arrays or out-of-range values return `-1`. Valid inputs with no outliers return `0`.

## Source

- The pinned [TheAlgorithms/R `correlation_analysis.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/biomedical/correlation_analysis.r) uses `quantile(x, 0.25)` and `quantile(x, 0.75)`, then strict IQR fence comparisons.
- R's default is type 7 and linearly interpolates between order statistics: [R `quantile` manual](https://stat.ethz.ch/R-manual/R-patched/library/stats/html/quantile.html).

## Workload and build

[`workload.json`](workload.json) covers outliers at both ends, a single high outlier, fractional quartile interpolation, boundary values, constant and singleton inputs, maximum length, and malformed arrays.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm iqr_outlier_indices --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/iqr_outlier_indices/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/i/iqr_outlier_indices.c`](../../../c/i/iqr_outlier_indices.c) |
| C3 | [`c3/i/iqr_outlier_indices.c3`](../../../c3/i/iqr_outlier_indices.c3) |
| C++ | [`cpp/i/iqr_outlier_indices.cpp`](../../../cpp/i/iqr_outlier_indices.cpp) |
| Elisa | [`elisa/i/iqr_outlier_indices.elisa`](../../../elisa/i/iqr_outlier_indices.elisa) |
| Nim | [`nim/i/iqr_outlier_indices.nim`](../../../nim/i/iqr_outlier_indices.nim) |
| Odin | [`odin/i/iqr_outlier_indices.odin`](../../../odin/i/iqr_outlier_indices.odin) |
| Rust | [`rust/i/iqr_outlier_indices.rs`](../../../rust/i/iqr_outlier_indices.rs) |
| V | [`v/i/iqr_outlier_indices.v`](../../../v/i/iqr_outlier_indices.v) |
| Zig | [`zig/i/iqr_outlier_indices.zig`](../../../zig/i/iqr_outlier_indices.zig) |
