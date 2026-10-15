# Gray code to decimal

Decode a reflected Gray-code bit string and return its nonnegative binary value.

## Contract

- The read-only signed 64-bit array is `[length, ASCII bits...]`.
- The declared length must match the number of following array elements and be from 1 through 63.
- Each character must be ASCII `0` or `1`; leading zeroes are accepted.
- The result is the decoded binary value, from 0 through `INT64_MAX`. Invalid or malformed input returns `-1`.
- Implementations carry the XOR of the Gray bits seen so far, then append that decoded bit to the result.

This benchmark follows `gray_to_decimal` in the pinned Python `binary_to_gray_code.py`. The source rejects empty strings and nonbinary characters, parses the Gray string as an integer, and decodes it with the source's repeated-XOR helper.

This string helper is distinct from [`gray_to_binary`](../gray_to_binary/README.md), which accepts a scalar integer, and [`binary_to_gray`](../../b/binary_to_gray/README.md), which encodes binary bits as a string.

## Workload and build

[`workload.json`](workload.json) includes the Python examples, leading zeroes, the maximum signed result, empty and malformed arrays, invalid characters, and an overlength string.

```sh
python3 benchmarks/build_abi.py --algorithm gray_to_decimal --language rust --family i64_array_scalar
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/g/gray_to_decimal/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gray_to_decimal.c`](../../../c/g/gray_to_decimal.c) |
| C3 | [`c3/g/gray_to_decimal.c3`](../../../c3/g/gray_to_decimal.c3) |
| C++ | [`cpp/g/gray_to_decimal.cpp`](../../../cpp/g/gray_to_decimal.cpp) |
| Elisa | [`elisa/g/gray_to_decimal.elisa`](../../../elisa/g/gray_to_decimal.elisa) |
| Nim | [`nim/g/gray_to_decimal.nim`](../../../nim/g/gray_to_decimal.nim) |
| Odin | [`odin/g/gray_to_decimal.odin`](../../../odin/g/gray_to_decimal.odin) |
| Rust | [`rust/g/gray_to_decimal.rs`](../../../rust/g/gray_to_decimal.rs) |
| V | [`v/g/gray_to_decimal.v`](../../../v/g/gray_to_decimal.v) |
| Zig | [`zig/g/gray_to_decimal.zig`](../../../zig/g/gray_to_decimal.zig) |

## Pinned source

- [TheAlgorithms/Python `binary_to_gray_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_gray_code.py)
