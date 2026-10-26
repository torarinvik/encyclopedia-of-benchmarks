# Triangular solve

This package ports the `init_array` and `kernel_trisolv` operations from
PolyBench/C [`trisolv.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/trisolv/trisolv.c)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source default type is
binary64. The launcher selects the `EXTRALARGE_DATASET` size of 40000; this
bounded suite profile accepts `1 <= n <= 40`, including the source's
`MINI_DATASET` size while keeping fixed workspace small.

The input is the one-element binary64 array `[n]`. Initialization follows the
source: `b[i] = i` and `L[i][j] = (double)(i + n - j + 1) * 2 / n` for
`0 <= j <= i < n`. The kernel processes rows in increasing order, subtracts
each lower-triangle product in increasing column order, then divides by the
diagonal. The function returns the full binary64 solution vector `x` in row
order. Invalid input returns `-1`; a null output pointer or capacity below n
returns `-2` without writing output.

The independent reference is [`benchmarks/trisolv_oracle.py`](../../trisolv_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/t/trisolv.c](../../../c/t/trisolv.c) |
| C3 | [c3/t/trisolv.c3](../../../c3/t/trisolv.c3) |
| C++ | [cpp/t/trisolv.cpp](../../../cpp/t/trisolv.cpp) |
| Elisa | [elisa/t/trisolv.elisa](../../../elisa/t/trisolv.elisa) |
| Nim | [nim/t/trisolv.nim](../../../nim/t/trisolv.nim) |
| Odin | [odin/t/trisolv.odin](../../../odin/t/trisolv.odin) |
| Rust | [rust/t/trisolv.rs](../../../rust/t/trisolv.rs) |
| V | [v/t/trisolv.v](../../../v/t/trisolv.v) |
| Zig | [zig/t/trisolv.zig](../../../zig/t/trisolv.zig) |

The shared `float64_slice_io` suite uses the following commands after its
runner integration:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm trisolv --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/t/trisolv/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm trisolv --languages c
```

## Upstream license

The pinned PolyBench/C repository includes the Ohio State University Software Distribution License at its repository root. The complete notice and redistribution conditions are reproduced in this package's [`LICENSE.txt`](LICENSE.txt).
