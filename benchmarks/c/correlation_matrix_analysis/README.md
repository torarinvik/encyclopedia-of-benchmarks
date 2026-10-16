# Correlation Matrix Analysis

Compute a Pearson correlation matrix, two-sided p-value matrix, and Bonferroni and Benjamini–Hochberg (FDR) corrected p-value matrices for a small complete dataset.

## Bounded contract

The `i64_array_bytes_output` input is `[4, p, row_major_values...]`, with exactly four observations and `p` in 2..5. Each signed integer value is in `[-1000,1000]`; constant columns are invalid. This fixed complete-data domain selects the pinned R source's default `method="pearson"` path, without its optional plotting or missing-row removal.

For every variable pair, the correlation is the centered cross-product sum divided by the square root of the two centered square sums. With exactly four observations, the source's Pearson test has two degrees of freedom and its two-sided p-value simplifies to `1 - abs(r)`. R initializes the p-value matrix with ones, so diagonal raw and adjusted p-values are 1; correlation diagonals are also 1. Multiple-testing adjustment operates on the upper-triangle pair values, using the number of variable pairs as the family size, and writes results symmetrically. The FDR method is R's Benjamini–Hochberg procedure.

Output is four `p × p` row-major matrices of little-endian IEEE-754 binary64 values, in this order: correlation, raw p-values, Bonferroni-adjusted p-values, FDR-adjusted p-values. Six little-endian signed-i64 summary fields follow: `[sample_size=4, variables=p, missing_rows=0, significant_uncorrected, significant_bonferroni, significant_fdr]`. A successful call returns the byte count `32*p*p + 48`; the maximum output capacity is 848 bytes. The workload declares an 848-byte workspace for that largest result. Invalid shape, out-of-range values, or constant columns return `-1`; insufficient output capacity or a null output pointer returns `-2`.

The pinned implementation is `correlation_matrix_analysis` in [TheAlgorithms/R `biomedical/correlation_analysis.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/biomedical/correlation_analysis.r) at commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. Its default method is Pearson, initializes p-value and adjusted matrices to one, tests each off-diagonal pair, adjusts only the upper-triangle p-values with `p.adjust`, then mirrors corrected values. The bounded workload excludes Spearman and Kendall methods, missing observations, nonnumeric columns, and plotting.

[`workload.json`](workload.json) contains perfect and non-perfect correlations, p-adjustment examples, the maximum output shape, invalid constant columns, and insufficient output capacity. The independent expected-byte oracle is [`correlation_matrix_analysis_oracle.py`](../../correlation_matrix_analysis_oracle.py).

| Language | Source |
| --- | --- |
| C | [`c/c/correlation_matrix_analysis.c`](../../../c/c/correlation_matrix_analysis.c) |
| C3 | [`c3/c/correlation_matrix_analysis.c3`](../../../c3/c/correlation_matrix_analysis.c3) |
| C++ | [`cpp/c/correlation_matrix_analysis.cpp`](../../../cpp/c/correlation_matrix_analysis.cpp) |
| Elisa | [`elisa/c/correlation_matrix_analysis.elisa`](../../../elisa/c/correlation_matrix_analysis.elisa) |
| Nim | [`nim/c/correlation_matrix_analysis.nim`](../../../nim/c/correlation_matrix_analysis.nim) |
| Odin | [`odin/c/correlation_matrix_analysis.odin`](../../../odin/c/correlation_matrix_analysis.odin) |
| Rust | [`rust/c/correlation_matrix_analysis.rs`](../../../rust/c/correlation_matrix_analysis.rs) |
| V | [`v/c/correlation_matrix_analysis.v`](../../../v/c/correlation_matrix_analysis.v) |
| Zig | [`zig/c/correlation_matrix_analysis.zig`](../../../zig/c/correlation_matrix_analysis.zig) |

## Build and record

Build a language implementation and record it with the shared bytes-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm correlation_matrix_analysis --language LANGUAGE --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/correlation_matrix_analysis/LANGUAGE/build.json
```
