# McGill Queens

This package ports the pinned [`queens.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/queens.c) program and its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/info.sh) launcher. The launcher selects only `queens.c`, links `-lm`, and passes no run options.

## Contract

The `i64_scalar_bytes_output` profile accepts a board dimension `n` from 1 through 14. It follows the source's count-only default: `printing` is zero, `findall` is one, and the recursive search tries files from left to right at each rank without symmetry reduction. Each call emits the source header and the singular or plural solution-count line as ASCII. Invalid dimensions return `-1`; null or short output for a valid dimension returns `-2` without writing.

The source supports dimensions through 100, but its no-argument launcher default is 14 and larger searches grow quickly. The profile keeps that launcher workload at its upper bound. Although the source comments describe `-a` as printing all boards, the pinned `main` resets `printing` to zero and the launcher passes no options, so the suite preserves actual launcher stdout. The independent [bit-mask oracle](../../queens_oracle.py) counts placements without reusing the source's owner-array search.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/q/queens.c`](../../../c/q/queens.c) |
| C3 | [`c3/q/queens.c3`](../../../c3/q/queens.c3) |
| C++ | [`cpp/q/queens.cpp`](../../../cpp/q/queens.cpp) |
| Elisa | [`elisa/q/queens.elisa`](../../../elisa/q/queens.elisa) |
| Nim | [`nim/q/queens.nim`](../../../nim/q/queens.nim) |
| Odin | [`odin/q/queens.odin`](../../../odin/q/queens.odin) |
| Rust | [`rust/q/queens.rs`](../../../rust/q/queens.rs) |
| V | [`v/q/queens.v`](../../../v/q/queens.v) |
| Zig | [`zig/q/queens.zig`](../../../zig/q/queens.zig) |

The shared scalar-bytes build, runner, and verifier use algorithm name `queens` and function symbol `queens`.
