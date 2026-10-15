# Decimal to Gray code

Convert a nonnegative decimal integer to the minimal-width binary string for
its reflected Gray-code value.

## Contract

- Input is one signed 64-bit integer in `[0, INT64_MAX]`.
- Compute `gray = n ^ (n >> 1)`, then write its binary digits most-significant
  first with no prefix or leading zeroes. Zero is written as `0`.
- Return the output byte count, from 1 through 63. The output contains ASCII
  `0` and `1` bytes and no trailing NUL.
- Negative inputs return `-1`. Insufficient output capacity returns `-2`
  without writing any bytes.
- The implementation uses constant auxiliary space and takes `O(log n)` time.

The exported C ABI entry point is:

```c
int64_t decimal_to_gray(int64_t value, uint8_t *output, size_t output_capacity);
```

The pinned [Python `decimal_to_gray`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_gray_code.py)
computes `binary_to_gray(n)` and formats that integer as unprefixed binary.
This scalar integer-to-string operation is separate from
[`binary_to_gray`](../../b/binary_to_gray/README.md), which accepts an existing
bit string and preserves its width, and from
[`gray_code`](../../g/gray_code/README.md),
which emits a sequence of Gray-code integers.

## Workload and build

[`workload.json`](workload.json) covers all pinned decimal conversion examples,
byte-width boundaries, the largest signed 64-bit input, and negative inputs.
All nine ports use the `i64_scalar_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm decimal_to_gray --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/d/decimal_to_gray/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_gray.c`](../../../c/d/decimal_to_gray.c) |
| C3 | [`c3/d/decimal_to_gray.c3`](../../../c3/d/decimal_to_gray.c3) |
| C++ | [`cpp/d/decimal_to_gray.cpp`](../../../cpp/d/decimal_to_gray.cpp) |
| Elisa | [`elisa/d/decimal_to_gray.elisa`](../../../elisa/d/decimal_to_gray.elisa) |
| Nim | [`nim/d/decimal_to_gray.nim`](../../../nim/d/decimal_to_gray.nim) |
| Odin | [`odin/d/decimal_to_gray.odin`](../../../odin/d/decimal_to_gray.odin) |
| Rust | [`rust/d/decimal_to_gray.rs`](../../../rust/d/decimal_to_gray.rs) |
| V | [`v/d/decimal_to_gray.v`](../../../v/d/decimal_to_gray.v) |
| Zig | [`zig/d/decimal_to_gray.zig`](../../../zig/d/decimal_to_gray.zig) |
