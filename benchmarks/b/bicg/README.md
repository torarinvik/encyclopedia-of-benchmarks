# BiCG: Bi-Conjugate Gradient kernel

This package ports the `PolyBench/linear-algebra/kernels/bicg/bicg.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source uses binary64 and initializes `p[j] = (j mod m)/m`, `r[i] = (i mod n)/n`, and `A[i][j] = (i*(j+1) mod n)/n`.

The `bicg` slug accepts signed 64-bit input `[m, n]`, with each dimension bounded to 1–64. The kernel zeroes `s`, then processes rows `i` in ascending order. For every row, it sets `q[i]` to zero and visits columns `j` in ascending order, first updating `s[j]` with `r[i] * A[i][j]`, then updating `q[i]` with `A[i][j] * p[j]`. The scalar result adds final `s` elements in ascending order followed by final `q` elements in ascending order, matching the order in which the source prints its live-out arrays. Invalid inputs return `-1e300`.

The upstream launcher selects `EXTRALARGE_DATASET` (`m=27000`, `n=33000`) and runs without arguments; this bounded profile caps both dimensions at 64. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for source and launcher details, bounds, and cases. The upstream source has no explicit license notice; these are independently written ports of the published kernel.

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm bicg --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/b/bicg/c/build.json
```
