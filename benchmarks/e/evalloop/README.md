# Misc Evalloop benchmark

The pinned launcher builds only `evalloop.c` and supplies no runtime arguments. Its source initializes a 2,048-entry command buffer: entries 0 through 2,046 contain `i % 31 + 1`, and the final entry is opcode zero. The computed-goto interpreter resets its program counter for each pass, dispatches 2,047 nonzero commands, calls `execute(opcode)` for each command, and returns when it reads zero. `execute` adds the opcode into a `uint32_t` sum. The launcher source runs 100,000 passes and prints `Sum: 3273700000` followed by LF.

This suite profile accepts 0 through 1,000 passes. The opcode buffer and sum semantics stay source-compatible. Since computed goto is a GNU C extension, the ports use each language's portable opcode dispatcher and preserve the same opcode stream and per-command sum update. The independent oracle uses the source stream's closed-form per-pass sum, `66 * sum(1..31) + 1 = 32737`, then applies uint32 wrapping.

The ABI is `i64_scalar_bytes_output`: `evalloop(passes, output, output_capacity)`. The input encoding is `evalloop_passes`; output encoding is `evalloop_stdout_ascii`. Invalid pass counts return -1. A null or short output buffer returns -2 without writes. See [`workload.json`](workload.json) and [`evalloop_oracle.py`](../../evalloop_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/e/evalloop.c](../../../c/e/evalloop.c) |
| C3 | [c3/e/evalloop.c3](../../../c3/e/evalloop.c3) |
| C++ | [cpp/e/evalloop.cpp](../../../cpp/e/evalloop.cpp) |
| Elisa | [elisa/e/evalloop.elisa](../../../elisa/e/evalloop.elisa) |
| Nim | [nim/e/evalloop.nim](../../../nim/e/evalloop.nim) |
| Odin | [odin/e/evalloop.odin](../../../odin/e/evalloop.odin) |
| Rust | [rust/e/evalloop.rs](../../../rust/e/evalloop.rs) |
| V | [v/e/evalloop.v](../../../v/e/evalloop.v) |
| Zig | [zig/e/evalloop.zig](../../../zig/e/evalloop.zig) |

## Pinned source

- [evalloop.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/evalloop.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/info.sh)
