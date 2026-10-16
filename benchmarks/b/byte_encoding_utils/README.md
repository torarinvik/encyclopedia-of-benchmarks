# Byte encoding utilities

The pinned C# utility reads unsigned 64-bit integers from big-endian byte spans and writes unsigned 64-bit integers to big-endian spans. The benchmark represents both operations as the same eight-byte reversal over a 64-bit bit pattern.

## Contract

- Input is any signed 64-bit value. Its bits either pack eight source bytes in little-endian order for `BigEndianToUint64`, or represent the input `UInt64` for `UInt64ToBigEndian`.
- Output is the same 64 bits with byte order reversed, returned as a signed 64-bit two’s-complement interpretation. Every bit pattern is valid.
- The signed ABI transports the source `ulong` bits; it does not apply signed arithmetic.

[`workload.json`](workload.json) covers zero, byte boundaries, distinct-byte patterns, signed boundaries, and deterministic mixed patterns. Build with `python3 benchmarks/build_abi.py --family scalar --algorithm byte_encoding_utils --language rust`; verify with `python3 benchmarks/verify_scalar.py --algorithms byte_encoding_utils --languages rust`.

All nine ports use portable integer shifts and masks (or the language's byte-swap intrinsic):

| Language | Source |
| --- | --- |
| C | [`c/b/byte_encoding_utils.c`](../../../c/b/byte_encoding_utils.c) |
| C3 | [`c3/b/byte_encoding_utils.c3`](../../../c3/b/byte_encoding_utils.c3) |
| C++ | [`cpp/b/byte_encoding_utils.cpp`](../../../cpp/b/byte_encoding_utils.cpp) |
| Elisa | [`elisa/b/byte_encoding_utils.elisa`](../../../elisa/b/byte_encoding_utils.elisa) |
| Nim | [`nim/b/byte_encoding_utils.nim`](../../../nim/b/byte_encoding_utils.nim) |
| Odin | [`odin/b/byte_encoding_utils.odin`](../../../odin/b/byte_encoding_utils.odin) |
| Rust | [`rust/b/byte_encoding_utils.rs`](../../../rust/b/byte_encoding_utils.rs) |
| V | [`v/b/byte_encoding_utils.v`](../../../v/b/byte_encoding_utils.v) |
| Zig | [`zig/b/byte_encoding_utils.zig`](../../../zig/b/byte_encoding_utils.zig) |

## TheAlgorithms reference

- [C# `ByteEncodingUtils.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/767c45a3e5fec99a4621fd99da9ea8d4877a2a4c/Algorithms/Crypto/Utils/ByteEncodingUtils.cs)
