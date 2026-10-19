# McCat bisect

This package implements McCat's `04-bisect` symmetric tridiagonal eigenvalue benchmark from pinned LAC-DCC commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The pinned launcher selects `allocvector.c`, `bisect_test.c`, and `dbisect.c`, links `-lm`, and reads `bisect_test.in` (`rep=1`, `n=500`, `eps=2.2204460492503131e-16`). The solver builds diagonal entries `(i+1)^4` and off-diagonal entries `i`, counts eigenvalues with the source Sturm recurrence, and bisects each requested interval.

## Contract

- Export `mccat_bisect` through the `i64_array_bytes_output` ABI. Input is exactly `[n]`, where `2 <= n <= 32`. The profile fixes the source's default repetition count to one and uses its input epsilon, binary64 `DBL_EPSILON`.
- Each successful output is a little-endian IEEE-754 binary64 vector: eigenvalues `lambda_2` through `lambda_n` in ascending eigenvalue order, followed by `eps2` and `k` (the source's Sturm bisection iteration count, represented exactly as binary64). The eigenvalue line number is implicit from the vector position.
- The source prints eigenvalues from `S[1]` through `S[n-1]` after passing `&S[-1]` to its 1-based solver. These ports model that intended shifted indexing safely, so the emitted sequence contains `lambda_2` through `lambda_n` and omits `lambda_1`, matching the launcher’s printed result values. The text padding and decimal formatting are represented as numeric binary64 values in the suite ABI.
- A valid call returns `(n+1)*8` bytes, up to 264 bytes at `n=32`. Invalid input returns `-1`. Null output or insufficient capacity returns `-2` without writes.
- The bounded profile caps the matrix order at 32 instead of the launcher's 500. The worst-case iteration work scales with the number of eigenvalues and the Sturm sequence length; the output is limited to 33 binary64 values.

The independent [oracle](../../mccat_bisect_oracle.py) follows the pinned `sturm` and `dbisect` source recurrence and emits the same numeric vector. `workload.json` includes bounded dimensions, framing and output-buffer errors, and float64 vector tolerances.

## Pinned source

- Launcher: [`McCat/04-bisect/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/04-bisect/info.sh)
- Solver: [`McCat/04-bisect/dbisect.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/04-bisect/dbisect.c)
- Driver: [`McCat/04-bisect/bisect_test.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/04-bisect/bisect_test.c)
- The upstream files retain the McGill University, McCAT System Group, and ACAPS Benchmark Administrator copyright/license notice.

The pinned notice is:

> Copyright (C) 1996 McGill University. Copyright (C) 1996 McCAT System Group. Copyright (C) 1996 ACAPS Benchmark Administrator. This program is free software; you can redistribute it and/or modify it provided this copyright notice is maintained. It is distributed in the hope that it will be useful, but without any warranty, including the implied warranties of merchantability or fitness for a particular purpose.

## Language ports

| Language | Source |
|---|---|
| C | [c/m/mccat_bisect.c](../../../c/m/mccat_bisect.c) |
| C3 | [c3/m/mccat_bisect.c3](../../../c3/m/mccat_bisect.c3) |
| C++ | [cpp/m/mccat_bisect.cpp](../../../cpp/m/mccat_bisect.cpp) |
| Elisa | [elisa/m/mccat_bisect.elisa](../../../elisa/m/mccat_bisect.elisa) |
| Nim | [nim/m/mccat_bisect.nim](../../../nim/m/mccat_bisect.nim) |
| Odin | [odin/m/mccat_bisect.odin](../../../odin/m/mccat_bisect.odin) |
| Rust | [rust/m/mccat_bisect.rs](../../../rust/m/mccat_bisect.rs) |
| V | [v/m/mccat_bisect.v](../../../v/m/mccat_bisect.v) |
| Zig | [zig/m/mccat_bisect.zig](../../../zig/m/mccat_bisect.zig) |
