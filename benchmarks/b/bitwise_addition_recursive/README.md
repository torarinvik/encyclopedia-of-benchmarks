# Recursive bitwise addition

Add two nonnegative integers using the pinned recursive XOR-and-carry algorithm.

## Contract

- The binary_scalar ABI accepts two signed 64-bit integer arguments.
- Each input must be in [0, 2,147,483,647]. Invalid inputs return -1.
- The result is the exact sum. The maximum valid output is 4,294,967,294, which fits signed 64-bit.
- Valid calls preserve the source recurrence: sum = a XOR b, carry = (a AND b) << 1, then recurse until carry is zero.

## Source semantics

This follows the pinned [TheAlgorithms Python bitwise_addition_recursive.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/bitwise_addition_recursive.py). The source rejects negative values and non-integers. The ABI supplies integers; the benchmark maps negative and out-of-range inputs to -1 and bounds each input to signed-32-bit nonnegative values.

## Workload

The workload covers the source examples, zero, carry propagation, complementary bit patterns, maximum inputs, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/bitwise_addition_recursive.c](../../../c/b/bitwise_addition_recursive.c) |
| C3 | [c3/b/bitwise_addition_recursive.c3](../../../c3/b/bitwise_addition_recursive.c3) |
| C++ | [cpp/b/bitwise_addition_recursive.cpp](../../../cpp/b/bitwise_addition_recursive.cpp) |
| Elisa | [elisa/b/bitwise_addition_recursive.elisa](../../../elisa/b/bitwise_addition_recursive.elisa) |
| Nim | [nim/b/bitwise_addition_recursive.nim](../../../nim/b/bitwise_addition_recursive.nim) |
| Odin | [odin/b/bitwise_addition_recursive.odin](../../../odin/b/bitwise_addition_recursive.odin) |
| Rust | [rust/b/bitwise_addition_recursive.rs](../../../rust/b/bitwise_addition_recursive.rs) |
| V | [v/b/bitwise_addition_recursive.v](../../../v/b/bitwise_addition_recursive.v) |
| Zig | [zig/b/bitwise_addition_recursive.zig](../../../zig/b/bitwise_addition_recursive.zig) |

The package uses the binary_scalar benchmark ABI.
