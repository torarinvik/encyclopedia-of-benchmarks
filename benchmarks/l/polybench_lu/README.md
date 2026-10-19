# PolyBench LU decomposition

This package ports PolyBench/C's initialized `kernel_lu` at pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher uses the header's default `LARGE_DATASET` (`N=2000`); the bounded suite accepts `1<=n<=6`. The distinct slug `polybench_lu` avoids collision with other LU packages in this repository.

## Contract

The `float64_slice_io` symbol is `polybench_lu(input,input_length,output,output_capacity)`. Input is `[n]` as one finite exact-integer binary64 value. Initialization first constructs a lower triangular matrix with diagonal 1, entries `1-j/n` below the diagonal, and zero above it. It then replaces A by the Gram matrix `A*A^T`, accumulating the inner product in ascending `t` order, matching `init_array`.

The kernel performs in-place LU factorization without pivoting, following the source loop order. For each row `i`, it computes the lower entries `j<i` by subtracting products for ascending `k<j` and dividing by the already-computed diagonal `A[j][j]`; it then computes entries `j>=i` by subtracting products for ascending `k<i`. The full combined LU matrix is returned row-major; the unit diagonal of L is implicit, while U occupies the upper triangle.

Invalid input returns -1. Null or undersized output returns -2 after input validation. Implementations stage results before writing, so errors leave output untouched. Maximum output is 36 doubles. The contract follows binary64 arithmetic and source accumulation order rather than formatted PolyBench output.

## Workload and oracle

[`workload.json`](workload.json) contains valid and invalid cases. [`benchmarks/polybench_lu_oracle.py`](../../polybench_lu_oracle.py) independently constructs the Gram matrix and applies the source-ordered factorization.

## Ports

The nine source ports are `c/l/polybench_lu.c`, `c3/l/polybench_lu.c3`, `cpp/l/polybench_lu.cpp`, `elisa/l/polybench_lu.elisa`, `nim/l/polybench_lu.nim`, `odin/l/polybench_lu.odin`, `rust/l/polybench_lu.rs`, `v/l/polybench_lu.v`, and `zig/l/polybench_lu.zig`.

## Pinned source and license

- [lu.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/lu/lu.c)
- [lu.h](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/lu/lu.h)
- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/lu/info.sh)
- [`LICENSE.txt`](LICENSE.txt) reproduces the pinned Ohio State University Software Distribution License and its redistribution conditions, public-release statement, disclaimer, and indemnification terms.
