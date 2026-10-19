# CoreMark CRC helpers

This package exercises CoreMark's four 16-bit CRC helper entry points over a small tagged record stream. Each record contains a helper tag, a 16-bit starting CRC, and a width-appropriate value. The scalar result is the sum of each helper result weighted by its one-based record position.

## Contract

Input is `[count, tag, seed, value, ...]`, with 1–16 records and exact length `1 + 3*count`. Tags 0, 1, 2, and 3 invoke `crcu8`, `crcu16`, `crcu32`, and `crc16`, respectively. Seeds are unsigned 16-bit values. The corresponding value domains are unsigned 8-bit, unsigned 16-bit, unsigned 32-bit, and signed 16-bit. Invalid input returns `-1`.

The implementation follows CoreMark `core_util.c`: `crcu8` processes data least-significant bit first with the source's `0x4002` feedback mask and 16-bit carry handling. `crcu16` feeds the low byte then high byte. `crcu32` feeds the low 16-bit half then the high half through `crc16`; `crc16` converts its signed 16-bit input to unsigned 16-bit and delegates to `crcu16`.

This is distinct from the repository's [`crc16`](../crc16/README.md) package, which implements the Java CRC-16/CCITT-FALSE variant (initial `0xFFFF`, polynomial `0x1021`, MSB-first bytes). CoreMark uses its own reflected bit recurrence and byte/halfword ordering; the names do not imply interchangeable checksums.

## Upstream attribution and license

The algorithm is independently reimplemented from EEMBC CoreMark's `core_util.c`, symbols `crcu8`, `crcu16`, `crcu32`, and `crc16`, pinned at [commit `1f483d5b8316753a742cbf5590caf5bd0a4e4777`](https://github.com/eembc/coremark/blob/1f483d5b8316753a742cbf5590caf5bd0a4e4777/core_util.c). Upstream attribution: Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC); original author Shay Gal-on. The upstream file is licensed under Apache-2.0; see [LICENSE-APACHE-2.0](LICENSE-APACHE-2.0). The language ports retain the applicable copyright and license notice.

| Language | Port |
|---|---|
| C | [`c/c/coremark_crc.c`](../../../c/c/coremark_crc.c) |
| C3 | [`c3/c/coremark_crc.c3`](../../../c3/c/coremark_crc.c3) |
| C++ | [`cpp/c/coremark_crc.cpp`](../../../cpp/c/coremark_crc.cpp) |
| Elisa | [`elisa/c/coremark_crc.elisa`](../../../elisa/c/coremark_crc.elisa) |
| Nim | [`nim/c/coremark_crc.nim`](../../../nim/c/coremark_crc.nim) |
| Odin | [`odin/c/coremark_crc.odin`](../../../odin/c/coremark_crc.odin) |
| Rust | [`rust/c/coremark_crc.rs`](../../../rust/c/coremark_crc.rs) |
| V | [`v/c/coremark_crc.v`](../../../v/c/coremark_crc.v) |
| Zig | [`zig/c/coremark_crc.zig`](../../../zig/c/coremark_crc.zig) |

Use the `i64_array_scalar` comparison model. The independent bounded oracle is [`coremark_crc_oracle.py`](../../coremark_crc_oracle.py); see [`workload.json`](workload.json).
