# XTEA

The benchmark ports the pinned Python implementation's single-block XTEA encryption. It operates on one 64-bit block, a 128-bit key, and a bounded round count, using unsigned 32-bit arithmetic and network byte order.

## Contract

The `i64_array_bytes_output` input is `[round_count, plaintext_byte_0..7, key_byte_0..15]`. It contains exactly 25 signed 64-bit values. The round count is 1–64 and all block/key values are bytes in [0, 255]. Invalid inputs return `-1`; insufficient output capacity returns `-2`. Output is exactly eight bytes: the encrypted 32-bit words serialized big-endian, matching Python's `struct.pack("!II", ...)`. Runtime is O(rounds) and auxiliary state is O(1).

[`workload.json`](workload.json) includes both pinned examples, one and partial round counts, and malformed lengths, bounds, and bytes.

## Pinned source

- [Python `xtea.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/xtea.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/x/xtea.c`](../../../c/x/xtea.c) |
| C3 | [`c3/x/xtea.c3`](../../../c3/x/xtea.c3) |
| C++ | [`cpp/x/xtea.cpp`](../../../cpp/x/xtea.cpp) |
| Elisa | [`elisa/x/xtea.elisa`](../../../elisa/x/xtea.elisa) |
| Nim | [`nim/x/xtea.nim`](../../../nim/x/xtea.nim) |
| Odin | [`odin/x/xtea.odin`](../../../odin/x/xtea.odin) |
| Rust | [`rust/x/xtea.rs`](../../../rust/x/xtea.rs) |
| V | [`v/x/xtea.v`](../../../v/x/xtea.v) |
| Zig | [`zig/x/xtea.zig`](../../../zig/x/xtea.zig) |
