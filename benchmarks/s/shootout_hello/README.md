# Shootout Hello benchmark

The pinned `hello.c` launcher compiles the source with `-lm` and passes no runtime options. Its `main` function calls `puts("hello world\n")` once. Since `puts` adds its own newline after the embedded newline, source stdout is exactly `hello world\n\n` (13 bytes).

The suite exposes the existing `i64_scalar_bytes_output` ABI with a one-valued `calls` selector. Only `calls = 1` is valid, matching the source's single call; other values return -1. A null or undersized output buffer returns -2 without writing. The exported function is `shootout_hello(calls, output, output_capacity)` and stages the fixed output before copying it.

[workload.json](workload.json) covers the source call, rejected scalar values, and buffer errors. [shootout_hello_oracle.py](../../shootout_hello_oracle.py) holds the exact expected stdout bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_hello.c](../../../c/s/shootout_hello.c) |
| C3 | [c3/s/shootout_hello.c3](../../../c3/s/shootout_hello.c3) |
| C++ | [cpp/s/shootout_hello.cpp](../../../cpp/s/shootout_hello.cpp) |
| Elisa | [elisa/s/shootout_hello.elisa](../../../elisa/s/shootout_hello.elisa) |
| Nim | [nim/s/shootout_hello.nim](../../../nim/s/shootout_hello.nim) |
| Odin | [odin/s/shootout_hello.odin](../../../odin/s/shootout_hello.odin) |
| Rust | [rust/s/shootout_hello.rs](../../../rust/s/shootout_hello.rs) |
| V | [v/s/shootout_hello.v](../../../v/s/shootout_hello.v) |
| Zig | [zig/s/shootout_hello.zig](../../../zig/s/shootout_hello.zig) |

## Pinned source

- [hello.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/hello.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/info.sh)
