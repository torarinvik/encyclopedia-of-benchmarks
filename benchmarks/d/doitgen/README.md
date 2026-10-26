# doitgen

This package ports the PolyBench/C `doitgen` kernel from the pinned lac-dcc revision. Input is `[nr, nq, np]`, representing the first three dimensions of `A[nr][nq][np]`; `C4` is an `np × np` matrix. The source initializes `A[r][q][p] = ((r*q+p) mod np)/np` and `C4[i][j] = (i*j mod np)/np`.

## Contract

Each dimension is a signed 64-bit integer bounded to 1–16. For each `(r,q)` pair in source order, the kernel computes `sum[p]` for `p` ascending, reducing `s` from zero to `np-1` with `A[r][q][s] * C4[s][p]`, then copies the completed `sum` vector into `A[r][q]` in ascending `p`. This two-phase update preserves the original slice before overwriting it. The scalar result sums final `A` elements in row-major `r,q,p` order, matching the source's live-out print order. Invalid inputs return `-1e300`.

The source defaults to binary64. Its launcher selects `EXTRALARGE_DATASET` (`nr=250`, `nq=220`, `np=270`); this suite profile caps every dimension at 16. Source and launcher are pinned to upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/doitgen). Ports are independently written.

| Language | Port |
|---|---|
| C | [`c/d/doitgen.c`](../../../c/d/doitgen.c) |
| C3 | [`c3/d/doitgen.c3`](../../../c3/d/doitgen.c3) |
| C++ | [`cpp/d/doitgen.cpp`](../../../cpp/d/doitgen.cpp) |
| Elisa | [`elisa/d/doitgen.elisa`](../../../elisa/d/doitgen.elisa) |
| Nim | [`nim/d/doitgen.nim`](../../../nim/d/doitgen.nim) |
| Odin | [`odin/d/doitgen.odin`](../../../odin/d/doitgen.odin) |
| Rust | [`rust/d/doitgen.rs`](../../../rust/d/doitgen.rs) |
| V | [`v/d/doitgen.v`](../../../v/d/doitgen.v) |
| Zig | [`zig/d/doitgen.zig`](../../../zig/d/doitgen.zig) |

Build a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm doitgen --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/d/doitgen/c/build.json
```

## Upstream license

The pinned PolyBench/C repository includes the Ohio State University Software Distribution License at its repository root. The complete notice and redistribution conditions are reproduced in this package's [`LICENSE.txt`](LICENSE.txt).
