# Binary XOR operator

## Contract

Compute the bitwise XOR of two nonnegative integers and return its binary representation as ASCII bytes. Input is exactly `[a, b]`, with both values in `0..2^31-1`. The output is `0b` followed by `a ^ b` padded with leading zeroes to the larger operand bit width. When both inputs are zero, the result uses width one and returns `0b0`. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns the number of output bytes.

The shared ABI is:

```c
int64_t binary_xor_operator(const int64_t *input, size_t length,
               uint8_t *output, size_t output_capacity);
```

The shared `run_i64_array_bytes_output.py` runner checks the padded binary representation before timing.

## Workload

[`workload.json`](workload.json) covers zero, equal and disjoint operands, the pinned examples, maximum-width inputs, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_xor_operator.c`](../../../c/b/binary_xor_operator.c) |
| C3 | [`c3/b/binary_xor_operator.c3`](../../../c3/b/binary_xor_operator.c3) |
| C++ | [`cpp/b/binary_xor_operator.cpp`](../../../cpp/b/binary_xor_operator.cpp) |
| Elisa | [`elisa/b/binary_xor_operator.elisa`](../../../elisa/b/binary_xor_operator.elisa) |
| Nim | [`nim/b/binary_xor_operator.nim`](../../../nim/b/binary_xor_operator.nim) |
| Odin | [`odin/b/binary_xor_operator.odin`](../../../odin/b/binary_xor_operator.odin) |
| Rust | [`rust/b/binary_xor_operator.rs`](../../../rust/b/binary_xor_operator.rs) |
| V | [`v/b/binary_xor_operator.v`](../../../v/b/binary_xor_operator.v) |
| Zig | [`zig/b/binary_xor_operator.zig`](../../../zig/b/binary_xor_operator.zig) |

## Upstream references

- [Python `binary_xor_operator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_xor_operator.py)
- [Ruby `binary_xor_operator.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/bit_manipulation/binary_xor_operator.rb)
