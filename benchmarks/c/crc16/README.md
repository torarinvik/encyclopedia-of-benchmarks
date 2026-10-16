# CRC16

This package ports the pinned Java CRC16 routine as a byte-array checksum using the CRC-16/CCITT-FALSE recurrence: initial value `0xFFFF`, polynomial `0x1021`, most-significant-bit-first byte processing, no reflection, and no final XOR.

Input is an array of 0 through 100,001 integer byte values. Each value must be in 0 through 255. The checksum is returned as a number from 0 through 65,535; this normalizes the Java implementation's uppercase hexadecimal string formatting while preserving the underlying checksum. Invalid lengths or values return `-1`.

The Java source accepts a `String` and calls `getBytes()` using the platform default charset. This package takes explicit bytes so every language receives the same sequence. The recurrence and final 16-bit value are otherwise preserved.

| Language | Port |
|---|---|
| C | [`c/c/crc16.c`](../../../c/c/crc16.c) |
| C3 | [`c3/c/crc16.c3`](../../../c3/c/crc16.c3) |
| C++ | [`cpp/c/crc16.cpp`](../../../cpp/c/crc16.cpp) |
| Elisa | [`elisa/c/crc16.elisa`](../../../elisa/c/crc16.elisa) |
| Nim | [`nim/c/crc16.nim`](../../../nim/c/crc16.nim) |
| Odin | [`odin/c/crc16.odin`](../../../odin/c/crc16.odin) |
| Rust | [`rust/c/crc16.rs`](../../../rust/c/crc16.rs) |
| V | [`v/c/crc16.v`](../../../v/c/crc16.v) |
| Zig | [`zig/c/crc16.zig`](../../../zig/c/crc16.zig) |

Pinned source: [TheAlgorithms/Java `CRC16.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/CRC16.java). Build with `i64_array_scalar` and record using `benchmarks/run_i64_array_scalar.py`; see [`workload.json`](workload.json).
