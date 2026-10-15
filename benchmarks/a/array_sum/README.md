# Array sum

Add every value in an integer array and return the cumulative total.

## Contract

- The `i64_array_scalar` ABI accepts `[count, values...]` and returns their sum.
- `count` is 0 through 1,024; each value is a nonnegative integer no greater than 1,000,000,000.
- Empty input returns 0. These bounds keep every valid total within signed 64-bit range on every target platform.
- A malformed packed array or an out-of-range value returns `-1`.
- The workload uses exact integer comparison.

## Source semantics

This adapts the pinned [TheAlgorithms Solidity `AddArray.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/AddArray.sol), which traverses the input array from beginning to end and adds each value to a running total. The source uses `uint256`; the shared contract bounds values and totals to signed 64-bit integers so the same inputs and outputs are representable in all nine benchmark languages. Catalog candidate `add_array` maps to this benchmark name.

## Workload

[`workload.json`](workload.json) covers empty, zero, single-value, and multiple-value arrays, plus malformed layouts and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/array_sum.c`](../../../c/a/array_sum.c) |
| C3 | [`c3/a/array_sum.c3`](../../../c3/a/array_sum.c3) |
| C++ | [`cpp/a/array_sum.cpp`](../../../cpp/a/array_sum.cpp) |
| Elisa | [`elisa/a/array_sum.elisa`](../../../elisa/a/array_sum.elisa) |
| Nim | [`nim/a/array_sum.nim`](../../../nim/a/array_sum.nim) |
| Odin | [`odin/a/array_sum.odin`](../../../odin/a/array_sum.odin) |
| Rust | [`rust/a/array_sum.rs`](../../../rust/a/array_sum.rs) |
| V | [`v/a/array_sum.v`](../../../v/a/array_sum.v) |
| Zig | [`zig/a/array_sum.zig`](../../../zig/a/array_sum.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
