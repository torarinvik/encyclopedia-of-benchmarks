# ANSIbench Whetstone operation core

This package runs a bounded deterministic profile of the double-precision Whetstone core. It is not an official Whetstone run and does not report WIPS, KWIPS, MWIPS, or a comparable score.

## Contract

Input is `[passes]`, where `passes` is 1 through 3. Each pass executes the complete source major-loop operation mix with the source `LOOP` parameter fixed to 1. This retains the source counts for Modules 1, 2, 3, 4, 6, 7, 8, 9, 10, and 11: respectively 0, 12, 14, 345, 210, 32, 899, 616, 0, and 93 loop iterations. Module 3 calls `PA` 14 times, and each call performs six update rounds. Modules 5 and 12 are omitted in the upstream C translation. Zero-count Modules 1 and 10 still initialize and expose their source state.

After each module, the final state values listed in the implementation are accumulated in a deterministic, one-based weighted projection. The function returns the sum of the per-pass projections weighted by the one-based pass number. Invalid, null, or trailing input returns `-1e300`. Compare float output with absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Upstream attribution and rights notice

The algorithm is based on ANSIbench `whetstone/src/whetstone.c`, pinned at [commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/whetstone/src/whetstone.c). The source identifies this as C Converted Whetstone Double Precision Benchmark Version 1.2 (22 March 1998), copyright 1998 Painter Engineering, Inc.; translated by Rich Painter from the Netlib `whetstoned` version obtained 16 March 1998. This package reimplements the operations and preserves the complete upstream comment block and limited-rights reference in each source file. The original notice permits use, duplication, and publication subject to retaining that block; it is not represented here as an OSI-approved open-source license. See [LICENSE](LICENSE).

| Language | Port |
|---|---|
| C | [`c/a/ansibench_whetstone.c`](../../../c/a/ansibench_whetstone.c) |
| C3 | [`c3/a/ansibench_whetstone.c3`](../../../c3/a/ansibench_whetstone.c3) |
| C++ | [`cpp/a/ansibench_whetstone.cpp`](../../../cpp/a/ansibench_whetstone.cpp) |
| Elisa | [`elisa/a/ansibench_whetstone.elisa`](../../../elisa/a/ansibench_whetstone.elisa) |
| Nim | [`nim/a/ansibench_whetstone.nim`](../../../nim/a/ansibench_whetstone.nim) |
| Odin | [`odin/a/ansibench_whetstone.odin`](../../../odin/a/ansibench_whetstone.odin) |
| Rust | [`rust/a/ansibench_whetstone.rs`](../../../rust/a/ansibench_whetstone.rs) |
| V | [`v/a/ansibench_whetstone.v`](../../../v/a/ansibench_whetstone.v) |
| Zig | [`zig/a/ansibench_whetstone.zig`](../../../zig/a/ansibench_whetstone.zig) |

The independent bounded source-order oracle is [`ansibench_whetstone_oracle.py`](../../ansibench_whetstone_oracle.py). The workload uses the `i64_array_float64` comparison model; see [`workload.json`](workload.json).
