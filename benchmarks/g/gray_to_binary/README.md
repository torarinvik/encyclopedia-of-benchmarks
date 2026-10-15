# Gray code to binary integer

Convert a nonnegative reflected Gray-code integer into its binary integer value
using the source's prefix-XOR loop.

## Contract

- The scalar input is one signed 64-bit integer in `[0, 9,223,372,036,854,775,807]`.
- Return the decoded binary integer in the same range. Negative inputs return
  `-1` as the benchmark's invalid-input sentinel.
- Starting with the most significant Gray bit, XOR each lower Gray prefix into
  the accumulated binary value. This uses at most 63 iterations and constant
  auxiliary space.

The benchmark follows the `gray_to_binary` helper in the pinned Python
`binary_to_gray_code.py`. That source validates nonnegative integer input, then
starts with `binary_number = gray_number` and repeatedly XORs in the remaining
right-shifted Gray prefixes.

This package measures the Gray-to-binary integer helper. It is separate from
the `binary_to_gray` string conversion, which preserves the width of an input
binary string.

## Workload and build

[`workload.json`](workload.json) includes the pinned examples, zero, the highest
single-bit Gray input, the signed 64-bit maximum, and negative boundaries.

```sh
python3 benchmarks/build_scalar.py --algorithm gray_to_binary --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/g/gray_to_binary/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gray_to_binary.c`](../../../c/g/gray_to_binary.c) |
| C3 | [`c3/g/gray_to_binary.c3`](../../../c3/g/gray_to_binary.c3) |
| C++ | [`cpp/g/gray_to_binary.cpp`](../../../cpp/g/gray_to_binary.cpp) |
| Elisa | [`elisa/g/gray_to_binary.elisa`](../../../elisa/g/gray_to_binary.elisa) |
| Nim | [`nim/g/gray_to_binary.nim`](../../../nim/g/gray_to_binary.nim) |
| Odin | [`odin/g/gray_to_binary.odin`](../../../odin/g/gray_to_binary.odin) |
| Rust | [`rust/g/gray_to_binary.rs`](../../../rust/g/gray_to_binary.rs) |
| V | [`v/g/gray_to_binary.v`](../../../v/g/gray_to_binary.v) |
| Zig | [`zig/g/gray_to_binary.zig`](../../../zig/g/gray_to_binary.zig) |

## Pinned source

- [TheAlgorithms/Python `binary_to_gray_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_gray_code.py)
