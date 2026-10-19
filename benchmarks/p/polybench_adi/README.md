# PolyBench ADI

This package ports the pinned PolyBench/C `adi` kernel from [`adi.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/adi/adi.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher selects `EXTRALARGE_DATASET` (`N=2000`, `TSTEPS=1000`). This bounded suite profile accepts `1 <= n <= 32` and `1 <= tsteps <= 20`, including the source's `MINI_DATASET` pair (`20`, `20`) with fixed local storage.

## Contract

Input is the signed 64-bit array `[n, tsteps]`. The source initializes `u[i][j]` to `(double)(i + n - j) / n`, then performs the column sweep followed by the row sweep for each time step. Each sweep keeps the pinned source's increasing forward recurrence and descending back substitution order. `v`, `p`, and `q` are internal work arrays.

The result is the full final `u` matrix in row-major order, encoded as `n*n` little-endian IEEE-754 binary64 values. The source launcher prints the full matrix to stderr with two fractional digits; this suite profile preserves every live-out cell in a numeric representation that can be compared with float64 tolerances. Invalid input returns `-1`. A null output pointer or capacity below `8*n*n` returns `-2` without writing. The maximum profile output is 8192 bytes.

See [`workload.json`](workload.json) for bounds and deterministic fixtures, and [`polybench_adi_oracle.py`](../../polybench_adi_oracle.py) for the separate reference model.

## Upstream license

The pinned source bundle is covered by the Ohio State University Software Distribution License, included in [`LICENSE.txt`](LICENSE.txt). It permits source and binary redistribution with or without modification under the listed conditions. The complete file preserves the copyright notice, conditions, disclaimer, university name restriction, funding statement, and user indemnification terms.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/polybench_adi.c](../../../c/p/polybench_adi.c) |
| C3 | [c3/p/polybench_adi.c3](../../../c3/p/polybench_adi.c3) |
| C++ | [cpp/p/polybench_adi.cpp](../../../cpp/p/polybench_adi.cpp) |
| Elisa | [elisa/p/polybench_adi.elisa](../../../elisa/p/polybench_adi.elisa) |
| Nim | [nim/p/polybench_adi.nim](../../../nim/p/polybench_adi.nim) |
| Odin | [odin/p/polybench_adi.odin](../../../odin/p/polybench_adi.odin) |
| Rust | [rust/p/polybench_adi.rs](../../../rust/p/polybench_adi.rs) |
| V | [v/p/polybench_adi.v](../../../v/p/polybench_adi.v) |
| Zig | [zig/p/polybench_adi.zig](../../../zig/p/polybench_adi.zig) |

The function symbol is `polybench_adi`. The package uses the existing `i64_array_bytes_output` ABI; the output is a float64 vector with absolute and relative tolerances of `1e-10`.
