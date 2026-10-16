# Parameterized CRC-8 model

This package calculates an 8-bit CRC from the model fields used by the pinned Go implementation. `Name` is metadata only and is omitted from the benchmark input.

Input is a signed-i64 vector `[poly, init, ref_in, ref_out, xor_out, byte_length, payload...]`. The length must be exactly `6 + byte_length`; `byte_length` is 0 through 100,001. `poly`, `init`, `xor_out`, and every payload byte are in 0 through 255. `ref_in` and `ref_out` must each be 0 or 1. Invalid input returns `-1`.

Start with `crc = init`. For each byte, reverse its eight bits when `ref_in` is 1, XOR it into `crc`, then process eight most-significant-bit-first steps: shift left and mask to 8 bits, XORing `poly` when the bit shifted out was set. After all bytes, reverse `crc` when `ref_out` is 1, then XOR `xor_out`. Return the resulting value in 0 through 255. This follows the pinned Go source's exact independent `RefIn` and `RefOut` behavior; `RefOut` causes a final reflection whenever enabled, whether or not `RefIn` was enabled.

The nine ports implement the same parameterized model:

| Language | Port |
|---|---|
| C | [`c/c/crc8_model.c`](../../../c/c/crc8_model.c) |
| C3 | [`c3/c/crc8_model.c3`](../../../c3/c/crc8_model.c3) |
| C++ | [`cpp/c/crc8_model.cpp`](../../../cpp/c/crc8_model.cpp) |
| Elisa | [`elisa/c/crc8_model.elisa`](../../../elisa/c/crc8_model.elisa) |
| Nim | [`nim/c/crc8_model.nim`](../../../nim/c/crc8_model.nim) |
| Odin | [`odin/c/crc8_model.odin`](../../../odin/c/crc8_model.odin) |
| Rust | [`rust/c/crc8_model.rs`](../../../rust/c/crc8_model.rs) |
| V | [`v/c/crc8_model.v`](../../../v/c/crc8_model.v) |
| Zig | [`zig/c/crc8_model.zig`](../../../zig/c/crc8_model.zig) |

The pinned source is [TheAlgorithms/Go `crc8.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/checksum/crc8.go). Build with `i64_array_scalar` and record with `benchmarks/run_i64_array_scalar.py`; [`workload.json`](workload.json) includes both standard models and the mixed reflection-flag cases.
