# Endian converter

The pinned Java class exposes both big-to-little and little-to-big conversions. Both methods use `Integer.reverseBytes`, so the benchmark represents their shared four-byte reversal operation.

## Contract

- Input is one signed 64-bit ABI value constrained to Java's signed 32-bit range.
- Return the signed 32-bit integer formed by reversing the input's four bytes, sign-extended to 64 bits.
- Inputs outside signed 32-bit range return `-2,147,483,649`, which is outside the valid output range.
- The operation is symmetric: applying it twice recovers the original value.

[`workload.json`](workload.json) covers byte patterns, negative values, int32 boundaries, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm endian_converter --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/e/endian_converter/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/e/endian_converter.c`](../../../c/e/endian_converter.c) |
| C3 | [`c3/e/endian_converter.c3`](../../../c3/e/endian_converter.c3) |
| C++ | [`cpp/e/endian_converter.cpp`](../../../cpp/e/endian_converter.cpp) |
| Elisa | [`elisa/e/endian_converter.elisa`](../../../elisa/e/endian_converter.elisa) |
| Nim | [`nim/e/endian_converter.nim`](../../../nim/e/endian_converter.nim) |
| Odin | [`odin/e/endian_converter.odin`](../../../odin/e/endian_converter.odin) |
| Rust | [`rust/e/endian_converter.rs`](../../../rust/e/endian_converter.rs) |
| V | [`v/e/endian_converter.v`](../../../v/e/endian_converter.v) |
| Zig | [`zig/e/endian_converter.zig`](../../../zig/e/endian_converter.zig) |

## TheAlgorithms reference

- [Java `EndianConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/EndianConverter.java)
