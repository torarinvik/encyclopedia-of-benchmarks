# Binary coded decimal

## Contract

Convert a signed 32-bit integer to the source's textual BCD representation. Each decimal digit becomes its own four-bit binary nibble, in most-significant decimal digit first order, with the literal `0b` prefix. For example, `12` becomes `0b00010010`; this is not the ordinary binary representation of twelve.

Inputs outside `[-2^31, 2^31 - 1]` return `-1` and no output. In-range negative values follow both pinned sources and encode as zero (`0b0000`). Zero also encodes as `0b0000`. The output length is two prefix bytes plus four bytes per decimal digit. Insufficient output capacity returns `-2`. The exported ABI is `int64_t binary_coded_decimal(int64_t value, uint8_t *output, size_t output_capacity)`.

The Rust source's `i32` argument sets the common range; the Python source accepts arbitrary-size integers. The shared contract makes the range explicit for all nine ports.

## Relation to ordinary base conversion

This operation converts decimal digits to packed four-bit BCD groups. [`decimal_to_binary`](../../d/decimal_to_binary/README.md) instead encodes the entire integer in ordinary base two, and [`decimal_to_any_base`](../../d/decimal_to_any_base/README.md) emits positional digits for a selected radix. Those contracts do not preserve one nibble per decimal digit, so BCD is a distinct conversion.

## Workload and recording

[`workload.json`](workload.json) covers the pinned examples, digit boundaries, the signed 32-bit maximum, negative-to-zero behavior, and out-of-range values. Runtime verification remains pending. Build and record with the shared scalar byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm binary_coded_decimal --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/b/binary_coded_decimal/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_coded_decimal.c`](../../../c/b/binary_coded_decimal.c) |
| C3 | [`c3/b/binary_coded_decimal.c3`](../../../c3/b/binary_coded_decimal.c3) |
| C++ | [`cpp/b/binary_coded_decimal.cpp`](../../../cpp/b/binary_coded_decimal.cpp) |
| Elisa | [`elisa/b/binary_coded_decimal.elisa`](../../../elisa/b/binary_coded_decimal.elisa) |
| Nim | [`nim/b/binary_coded_decimal.nim`](../../../nim/b/binary_coded_decimal.nim) |
| Odin | [`odin/b/binary_coded_decimal.odin`](../../../odin/b/binary_coded_decimal.odin) |
| Rust | [`rust/b/binary_coded_decimal.rs`](../../../rust/b/binary_coded_decimal.rs) |
| V | [`v/b/binary_coded_decimal.v`](../../../v/b/binary_coded_decimal.v) |
| Zig | [`zig/b/binary_coded_decimal.zig`](../../../zig/b/binary_coded_decimal.zig) |

## TheAlgorithms references

- Rust [`binary_coded_decimal.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/binary_coded_decimal.rs)
- Python [`binary_coded_decimal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_coded_decimal.py)
