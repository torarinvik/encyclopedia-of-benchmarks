# CoyoteBench Huffbench

The pinned `CoyoteBench/huffbench/info.sh` launcher builds only `huffbench.c` and passes no run-time arguments. The source generates a byte buffer from its Park–Miller generator seeded at 1325, using the 32-character alphabet `ABCDEFGHIJKLMNOPQRSTUVWXYZ012345`, then repeats Huffman compression and decompression. Its ordinary compile-time profile uses 10,000,000 input bytes and 30 rounds. The launcher reports elapsed time, while this suite profile returns a deterministic summary of the kernel result.

This bounded profile keeps the same generator, frequency heap, source code construction, MSB-first packing, and round-trip decode. It fixes the generated buffer at 4,096 bytes and exposes the source round count as an input from 1 through 30. The output reports the encoded byte count and the modulo-2^32 sum of the decoded bytes. The oracle derives the source heap’s code lengths from generated frequencies and computes the corresponding packed size independently.

The source header attributes the work to Scott Robert Ladd and states, “No rights reserved. This is public domain software, for use by anyone.” The attribution and notice are included in [`LICENSE.txt`](LICENSE.txt).

The ABI is `i64_scalar_bytes_output`: `coyote_huffbench(passes, output, output_capacity)`. The input encoding is `huffbench_round_count`; the output encoding is `huffbench_summary_ascii`. Invalid pass counts return -1. Null or short output buffers return -2 without writes. See [`workload.json`](workload.json) and [`huffbench_oracle.py`](../../huffbench_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/huffbench.c](../../../c/h/huffbench.c) |
| C3 | [c3/h/huffbench.c3](../../../c3/h/huffbench.c3) |
| C++ | [cpp/h/huffbench.cpp](../../../cpp/h/huffbench.cpp) |
| Elisa | [elisa/h/huffbench.elisa](../../../elisa/h/huffbench.elisa) |
| Nim | [nim/h/huffbench.nim](../../../nim/h/huffbench.nim) |
| Odin | [odin/h/huffbench.odin](../../../odin/h/huffbench.odin) |
| Rust | [rust/h/huffbench.rs](../../../rust/h/huffbench.rs) |
| V | [v/h/huffbench.v](../../../v/h/huffbench.v) |
| Zig | [zig/h/huffbench.zig](../../../zig/h/huffbench.zig) |

## Pinned source

- [huffbench.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/huffbench.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/info.sh)
