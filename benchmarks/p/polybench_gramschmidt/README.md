# PolyBench modified Gram–Schmidt QR

This package ports the `kernel_gramschmidt` modified Gram–Schmidt QR operation from PolyBench/C 4.2.1 beta. It is a distinct source profile from the local `gram_schmidt` benchmark, which returns unnormalized orthogonal rows and does not compute R.

## Contract

The `float64_slice_io` ABI accepts `[m,n]` as two finite, exact-integer binary64 values, with `1 <= n <= m <= 6`. It initializes `A[i][j] = ((((i*j) mod m) / m) * 100) + 10`, with binary64 operations and source order, and initializes Q and R to zero. For each column k in ascending order, it computes the norm from the current A column, writes `R[k][k] = sqrt(norm)`, normalizes the Q column, then for each later column j computes `R[k][j]` and updates A in ascending i order. This is the source's modified Gram–Schmidt recurrence.

The output is R row-major followed by Q row-major, preserving the order of the source's live-out dump. It contains `n*n + m*n` binary64 values and the function returns that element count. Invalid input returns -1. Null or undersized output returns -2 without writes. Maximum output is 72 values. The profile excludes timer, allocation, and formatted text output.

## Source and rights

- [Official PolyBench/C 4.2.1 beta kernel](https://github.com/ferrandi/PolyBenchC/blob/main/linear-algebra/solvers/gramschmidt/gramschmidt.c), stamped May 10, 2016.
- [Official dataset/type header](https://github.com/ferrandi/PolyBenchC/blob/main/linear-algebra/solvers/gramschmidt/gramschmidt.h).
- The package's reproducibility pin is the matching [LAC-DCC source snapshot](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/gramschmidt).
- The official repository's [Ohio State University Software Distribution License](https://github.com/ferrandi/PolyBenchC/blob/main/LICENSE.txt) is included in [`LICENSE.txt`](LICENSE.txt) in full.

## Workload and ports

[`workload.json`](workload.json) records bounds and source-derived fixtures. [`benchmarks/polybench_gramschmidt_oracle.py`](../../polybench_gramschmidt_oracle.py) independently computes the initialized QR profile. Nine ports are provided for C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig.
