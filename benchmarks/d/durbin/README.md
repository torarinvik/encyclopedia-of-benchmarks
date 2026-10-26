# Durbin recurrence

This package ports PolyBench/C's `kernel_durbin` and deterministic `init_array`
from [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/durbin/durbin.c)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The default source type is
binary64. The bounded input `[n]` uses `1 <= n <= 40`, matching the source's
`MINI_DATASET` size, and initializes `r[i] = n + 1 - i` exactly as the source
does.

The function returns the n binary64 values of `y` in source order. It preserves
the recurrence, ascending accumulation loops, temporary `z` updates, and copy
order. Invalid input returns `-1`; a null output pointer or capacity below n
returns `-2` without writing output. The independent oracle is
[`benchmarks/durbin_oracle.py`](../../durbin_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/durbin.c](../../../c/d/durbin.c) |
| C3 | [c3/d/durbin.c3](../../../c3/d/durbin.c3) |
| C++ | [cpp/d/durbin.cpp](../../../cpp/d/durbin.cpp) |
| Elisa | [elisa/d/durbin.elisa](../../../elisa/d/durbin.elisa) |
| Nim | [nim/d/durbin.nim](../../../nim/d/durbin.nim) |
| Odin | [odin/d/durbin.odin](../../../odin/d/durbin.odin) |
| Rust | [rust/d/durbin.rs](../../../rust/d/durbin.rs) |
| V | [v/d/durbin.v](../../../v/d/durbin.v) |
| Zig | [zig/d/durbin.zig](../../../zig/d/durbin.zig) |

Run this benchmark through the shared `float64_slice_io` suite:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm durbin --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/d/durbin/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm durbin --languages c
```

## Upstream license

The pinned PolyBench/C repository includes the Ohio State University Software Distribution License at its repository root. The complete notice and redistribution conditions are reproduced in this package's [`LICENSE.txt`](LICENSE.txt).
