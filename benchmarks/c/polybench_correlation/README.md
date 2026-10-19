# PolyBench correlation matrix

This package ports PolyBench/C's initialized `kernel_correlation` at pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The package uses the distinct slug `polybench_correlation`; the repository's existing scalar `correlation` functions are unrelated. The launcher defaults to `LARGE_DATASET` (`N=1400`, `M=1200`); this bounded profile accepts `1<=n,m<=6`.

## Contract

The `float64_slice_io` symbol is `polybench_correlation(input,input_length,output,output_capacity)`. Input is `[n,m]` as finite, exact-integer binary64 values. Initialize `float_n=n` and `data[i][j]=(i*j)/m+i` in binary64. For each column, compute the mean by summing rows ascending and dividing by `n`; compute population standard deviation from squared deviations, summing rows ascending, divide by `n`, and take square root. Replace any standard deviation `<=0.1` by 1. Center and reduce each data element by dividing by `sqrt(float_n)*stddev[j]`. Then compute correlation entries in source order: set each diagonal to 1, sum normalized products for each upper-triangle pair with rows ascending, mirror the result, and set the final diagonal to 1.

Return the complete `m*m` correlation matrix row-major. Invalid input returns -1; null or undersized output returns -2 after validation. Implementations stage the result before writing, so errors do not modify output. Maximum output is 36 doubles. The numeric vector follows binary64 operations and source loop order rather than the source's formatted dump.

## Workload and oracle

[`workload.json`](workload.json) specifies valid and invalid cases. [`benchmarks/polybench_correlation_oracle.py`](../../polybench_correlation_oracle.py) independently carries out initialization, standardization, and pairwise accumulation.

## Ports

Ports are in `c/c/polybench_correlation.c`, `c3/c/polybench_correlation.c3`, `cpp/c/polybench_correlation.cpp`, `elisa/c/polybench_correlation.elisa`, `nim/c/polybench_correlation.nim`, `odin/c/polybench_correlation.odin`, `rust/c/polybench_correlation.rs`, `v/c/polybench_correlation.v`, and `zig/c/polybench_correlation.zig`.

## Pinned source and license

- [correlation.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/correlation/correlation.c)
- [correlation.h](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/correlation/correlation.h)
- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/correlation/info.sh)
- [`LICENSE.txt`](LICENSE.txt) reproduces the pinned Ohio State University Software Distribution License, including its redistribution conditions, public-release statement, disclaimer, and indemnification terms.
