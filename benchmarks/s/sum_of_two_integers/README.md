# Sum of two integers

Add two signed integers with the XOR and carry algorithm from the pinned Rust [`sum_of_two_integers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/sum_of_two_integers.rs). Each round computes the partial sum with XOR and shifts the shared set bits left to form the next carry.

## Contract

- Input is exactly `[a, b]`, with each value in the signed 32-bit range.
- Return the exact mathematical sum as a signed 64-bit integer. The two signed 32-bit inputs always have a sum in the signed 64-bit range, so this contract has no wraparound cases.
- Invalid input length or an operand outside signed 32-bit range returns `-1`.
- The source uses Rust `isize`; the benchmark uses the same XOR/AND/shift loop with a 64-bit machine word, matching the repository's 64-bit benchmark target.

This is distinct from ordinary addition benchmarks: the implementation computes carries using bit operations instead of an addition operator.

[`workload.json`](workload.json) includes the pinned source cases, signed 32-bit endpoints, negative operands, carry propagation, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_two_integers.c`](../../../c/s/sum_of_two_integers.c) |
| C3 | [`c3/s/sum_of_two_integers.c3`](../../../c3/s/sum_of_two_integers.c3) |
| C++ | [`cpp/s/sum_of_two_integers.cpp`](../../../cpp/s/sum_of_two_integers.cpp) |
| Elisa | [`elisa/s/sum_of_two_integers.elisa`](../../../elisa/s/sum_of_two_integers.elisa) |
| Nim | [`nim/s/sum_of_two_integers.nim`](../../../nim/s/sum_of_two_integers.nim) |
| Odin | [`odin/s/sum_of_two_integers.odin`](../../../odin/s/sum_of_two_integers.odin) |
| Rust | [`rust/s/sum_of_two_integers.rs`](../../../rust/s/sum_of_two_integers.rs) |
| V | [`v/s/sum_of_two_integers.v`](../../../v/s/sum_of_two_integers.v) |
| Zig | [`zig/s/sum_of_two_integers.zig`](../../../zig/s/sum_of_two_integers.zig) |

## Workload

The `i64_array_scalar` ABI accepts the two signed 64-bit input slots and returns one signed 64-bit scalar.
