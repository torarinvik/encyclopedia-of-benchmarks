# Shootout Methcall benchmark

The pinned launcher compiles `methcall.c` with `-lm` and supplies no run options. `main` creates two objects whose initial state is true. The `Toggle` changes state on every activation. The `NthToggle` changes state after every third activation and resets its counter to zero. Each object stores separate activation and value callbacks, and both callbacks are invoked indirectly for every loop iteration. Each loop stores the value returned by the activation/value call chain. The source then calls `puts` twice on strings that already end in LF, so each state is followed by two newline bytes.

The suite exposes `shootout_methcall(calls, output, output_capacity)` through the `i64_scalar_bytes_output` ABI. The bounded profile accepts -100,000 through 100,000 calls; negative counts execute zero iterations under the source loop condition. The first output state is true after an even number of calls. The second state flips once for every three calls. Inputs outside the profile return -1. A null or undersized output buffer returns -2 without writing.

The pinned launcher defaults to 500,000,000 calls (50,000,000 with `SMALL_PROBLEM_SIZE`). The bounded profile keeps the callback dispatch loops finite while retaining both state machines and their per-call updates. The language ports keep activation and value callbacks on each object so the hot loops retain indirect dispatch. C3 uses `void*` callback contexts because ordinary `.c3` modules cannot forward-declare these object types; it still makes the two indirect callback calls on every iteration. [`workload.json`](workload.json) covers the flip boundaries, counter reset, source framing, profile bounds, and buffer errors. [`shootout_methcall_oracle.py`](../../shootout_methcall_oracle.py) independently simulates both state machines.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_methcall.c](../../../c/s/shootout_methcall.c) |
| C3 | [c3/s/shootout_methcall.c3](../../../c3/s/shootout_methcall.c3) |
| C++ | [cpp/s/shootout_methcall.cpp](../../../cpp/s/shootout_methcall.cpp) |
| Elisa | [elisa/s/shootout_methcall.elisa](../../../elisa/s/shootout_methcall.elisa) |
| Nim | [nim/s/shootout_methcall.nim](../../../nim/s/shootout_methcall.nim) |
| Odin | [odin/s/shootout_methcall.odin](../../../odin/s/shootout_methcall.odin) |
| Rust | [rust/s/shootout_methcall.rs](../../../rust/s/shootout_methcall.rs) |
| V | [v/s/shootout_methcall.v](../../../v/s/shootout_methcall.v) |
| Zig | [zig/s/shootout_methcall.zig](../../../zig/s/shootout_methcall.zig) |

## Pinned source

- [methcall.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/methcall.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/info.sh)
