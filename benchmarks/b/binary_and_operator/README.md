# Binary AND operator

## Contract

Compute the bitwise AND of two nonnegative integers and return its binary representation as ASCII bytes. Input is exactly `[a, b]`, with both values in `0..2^31-1`. The output is `0b` followed by the AND result padded with leading zeroes to the larger operand bit width. When both inputs are zero, the result uses width one and returns `0b0`. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns the number of output bytes.

The Python source specifies width padding to the longer operand, while the Ruby source returns the unpadded integer representation. This benchmark uses the Python formatting behavior and records that source difference here.

The shared ABI is:

```c
int64_t binary_and_operator(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity);
```

## Workload

[`workload.json`](workload.json) covers the pinned examples, zero, equal operands, disjoint bits, and signed-32-bit maximum operands.

The shared byte-output runner validates the two operands, applies the width rule above, and returns the padded ASCII bit string.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_and_operator --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm binary_and_operator
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_and_operator.c`](../../../c/b/binary_and_operator.c) |
| C3 | [`c3/b/binary_and_operator.c3`](../../../c3/b/binary_and_operator.c3) |
| C++ | [`cpp/b/binary_and_operator.cpp`](../../../cpp/b/binary_and_operator.cpp) |
| Elisa | [`elisa/b/binary_and_operator.elisa`](../../../elisa/b/binary_and_operator.elisa) |
| Nim | [`nim/b/binary_and_operator.nim`](../../../nim/b/binary_and_operator.nim) |
| Odin | [`odin/b/binary_and_operator.odin`](../../../odin/b/binary_and_operator.odin) |
| Rust | [`rust/b/binary_and_operator.rs`](../../../rust/b/binary_and_operator.rs) |
| V | [`v/b/binary_and_operator.v`](../../../v/b/binary_and_operator.v) |
| Zig | [`zig/b/binary_and_operator.zig`](../../../zig/b/binary_and_operator.zig) |

## Upstream references

- [Python `binary_and_operator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_and_operator.py)
- [Ruby `binary_and_operator.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/bit_manipulation/binary_and_operator.rb)
