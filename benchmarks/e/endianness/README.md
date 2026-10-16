# Endianness conversion helpers

The pinned Python module provides three fixed-width byte swaps and four byte/integer conversion helpers. This benchmark uses one operation selector to expose all seven source functions through the `i64_array_scalar` ABI. The selector and layouts are documented below; only well-formed source-domain inputs are required.

## Contract

Input is a signed-i64 array with one of these layouts:

| Operation | Layout | Source operation |
|---:|---|---|
| 0 | `[0, value]` where `0 <= value <= 65535` | `swap_endianness_16` |
| 1 | `[1, value]` where `0 <= value <= 4294967295` | `swap_endianness_32` |
| 2 | `[2, value_bits]` for any signed-i64 bit pattern | `swap_endianness_64` on the corresponding UInt64 bits |
| 3 | `[3, count, bytes...]`, count 1..8 and bytes 0..255 | `bytes_to_int_little` |
| 4 | `[4, count, bytes...]`, count 1..8 and bytes 0..255 | `bytes_to_int_big` |
| 5 | `[5, value_bits, count]`, count 1..8 | `int_to_bytes_little` |
| 6 | `[6, value_bits, count]`, count 1..8 | `int_to_bytes_big` |

For modes 5 and 6, `value_bits` transports an unsigned 64-bit integer as an i64 bit pattern; when `count < 8`, the value must fit in that many bytes. The returned scalar is the UInt64 result as signed-i64 bits for modes 0 through 4. For modes 5 and 6, it is the output byte sequence packed as a little-endian UInt64 bit pattern. Malformed or out-of-domain arrays return `-1`; all valid outputs, including the `I64_MIN` bit pattern, are preserved.

[`workload.json`](workload.json) covers all seven operations, fixed-width boundaries, byte patterns, high-bit u64 values, malformed layouts, and deterministic mixed inputs. The package source is [Python `endianness.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/endianness.py).

## Implementations

The nine ports use portable shifts, masks, and fixed-width integer packing:

| Language | Source |
|---|---|
| C | [`c/e/endianness/endianness.c`](../../../c/e/endianness/endianness.c) |
| C3 | [`c3/e/endianness/endianness.c3`](../../../c3/e/endianness/endianness.c3) |
| C++ | [`cpp/e/endianness/endianness.cpp`](../../../cpp/e/endianness/endianness.cpp) |
| Elisa | [`elisa/e/endianness/endianness.elisa`](../../../elisa/e/endianness/endianness.elisa) |
| Nim | [`nim/e/endianness/endianness.nim`](../../../nim/e/endianness/endianness.nim) |
| Odin | [`odin/e/endianness/endianness.odin`](../../../odin/e/endianness/endianness.odin) |
| Rust | [`rust/e/endianness/endianness.rs`](../../../rust/e/endianness/endianness.rs) |
| V | [`v/e/endianness/endianness.v`](../../../v/e/endianness/endianness.v) |
| Zig | [`zig/e/endianness/endianness.zig`](../../../zig/e/endianness/endianness.zig) |
