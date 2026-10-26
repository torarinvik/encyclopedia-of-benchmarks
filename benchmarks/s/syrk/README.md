# SYRK: symmetric rank-k update

This package ports PolyBench/C's `init_array` and `kernel_syrk` from the pinned [`syrk.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syrk/syrk.c), with dataset and type definitions from [`syrk.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syrk/syrk.h). The source and launcher are pinned to commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syrk/info.sh) selects all `.c` files, passes `-I. -DPOLYBENCH_DUMP_ARRAYS -DEXTRALARGE_DATASET`, and sets no run options.

## Contract

The ABI is `float64_slice_io`. Its two-value input is `[n, m]`, with integral dimensions `1 <= n <= 8` and `1 <= m <= 16`. The bound on `n` keeps the complete `n*n` result within the shared 64-element output capacity. The source initializes `A[i][k]=((i*k+1)%n)/n` before initializing `C[i][j]=((i*j+2)%m)/m`, with `alpha=1.5` and `beta=1.2`.

For each `i` in ascending order, the kernel first scales `C[i][j]` by beta for ascending `j <= i`. It then visits `k` ascending and updates each `j <= i` ascending with `C[i][j] += alpha*A[i][k]*A[j][k]`. Entries above the diagonal retain their initialized values. The function returns the full C matrix in row-major order, the same element order traversed by the source's `print_array`; the suite compares unrounded binary64 values. Invalid dimensions return `-1`. A null output pointer or short capacity returns `-2` without writing.

The pinned launcher selects `EXTRALARGE_DATASET` (`n=2600`, `m=2000`), which is too large for the shared array-output ABI. The suite uses the documented bounded profile. The independent [`syrk_oracle.py`](../../syrk_oracle.py) reproduces the source initialization, lower-triangle update, and order. [`workload.json`](workload.json) includes the initialization dimensions, boundary and malformed inputs, and matrix outputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/syrk.c`](../../../c/s/syrk.c) |
| C3 | [`c3/s/syrk.c3`](../../../c3/s/syrk.c3) |
| C++ | [`cpp/s/syrk.cpp`](../../../cpp/s/syrk.cpp) |
| Elisa | [`elisa/s/syrk.elisa`](../../../elisa/s/syrk.elisa) |
| Nim | [`nim/s/syrk.nim`](../../../nim/s/syrk.nim) |
| Odin | [`odin/s/syrk.odin`](../../../odin/s/syrk.odin) |
| Rust | [`rust/s/syrk.rs`](../../../rust/s/syrk.rs) |
| V | [`v/s/syrk.v`](../../../v/s/syrk.v) |
| Zig | [`zig/s/syrk.zig`](../../../zig/s/syrk.zig) |

## Build and verify

~~~sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm syrk --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/s/syrk/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm syrk --languages c
~~~

## Upstream license

The pinned PolyBench/C repository includes the Ohio State University Software Distribution License at its repository root. The complete notice and redistribution conditions are reproduced in this package's [`LICENSE.txt`](LICENSE.txt).
