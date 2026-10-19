# PolyBench TRMM

This package ports the initialized `kernel_trmm` operation from PolyBench/C's `trmm` benchmark at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The pinned launcher selects `EXTRALARGE_DATASET` (`M=2000`, `N=2600`); this bounded profile accepts `1 <= m,n <= 8` and evaluates the same source loops and initialization without reproducing the large textual dump.

## Contract

The `float64_slice_io` symbol is `trmm(input, input_length, output, output_capacity)`. Input is `[m,n]` as two finite, exact-integer binary64 values. Initialization uses `alpha=1.5`, `A[i][j]=((i+j)%m)/m` for `j<i`, `A[i][i]=1`, and `B[i][j]=((n+i-j)%n)/n`. The kernel preserves the source's loop order: for ascending `i,j`, accumulate `A[k][i]*B[k][j]` into `B[i][j]` for ascending `k=i+1..m-1`, then multiply by alpha. Output is the complete `m*n` binary64 B matrix in row-major order.

Malformed dimensions return -1. A null or undersized output returns -2. Validation precedes capacity checks and implementations stage results before writing. Maximum output is 64 doubles. The numeric-vector contract preserves source arithmetic order; it does not serialize PolyBench's `%0.2lf` dump formatting.

## Workload and oracle

[`workload.json`](workload.json) covers unit, rectangular, and maximum bounded dimensions, invalid dimensions, null output, and insufficient capacity. [`benchmarks/trmm_oracle.py`](../../trmm_oracle.py) independently initializes and evaluates the source recurrence.

## Implementations

| Language | Source |
|---|---|
| C | [c/t/trmm.c](../../../c/t/trmm.c) |
| C3 | [c3/t/trmm.c3](../../../c3/t/trmm.c3) |
| C++ | [cpp/t/trmm.cpp](../../../cpp/t/trmm.cpp) |
| Elisa | [elisa/t/trmm.elisa](../../../elisa/t/trmm.elisa) |
| Nim | [nim/t/trmm.nim](../../../nim/t/trmm.nim) |
| Odin | [odin/t/trmm.odin](../../../odin/t/trmm.odin) |
| Rust | [rust/t/trmm.rs](../../../rust/t/trmm.rs) |
| V | [v/t/trmm.v](../../../v/t/trmm.v) |
| Zig | [zig/t/trmm.zig](../../../zig/t/trmm.zig) |

## Pinned source and license

- [`trmm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/trmm/trmm.c)
- [`trmm.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/trmm/trmm.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/trmm/info.sh)
- [`LICENSE.txt`](LICENSE.txt) reproduces the [pinned Ohio State University Software Distribution License](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/LICENSE.txt). The grant permits source and binary redistribution with the specified notice, disclaimer, no-endorsement condition, public-release statement, and indemnification, defense, and hold-harmless terms.
