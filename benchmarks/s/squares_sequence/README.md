# Squares sequence

## Contract

The input is a zero-based index `n` from 0 through 3,037,000,499. Return the square number `n²`; the sequence begins `0, 1, 4, 9, 16, ...`. Return `-1` outside that range. The upper bound is the largest index whose square fits in a signed 64-bit result.

The scalar ABI is `int64_t squares_sequence(int64_t index)`. The largest supported input returns 9,223,372,030,926,249,001. The next term, at index 3,037,000,500, exceeds `INT64_MAX`.

## Source behavior

The pinned C# generator initializes a `BigInteger` value to zero, yields `n * n`, then increments `n`. The benchmark uses zero-based indexing, so input 0 selects the first term, 0².

## Related sequences

[`square_pyramidal_numbers`](../square_pyramidal_numbers/README.md) returns sums of consecutive squares. This package returns the individual square terms.

## Workload

[`workload.json`](workload.json) covers initial terms, a middle term, the largest signed 64-bit square, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/squares_sequence.c`](../../../c/s/squares_sequence.c) |
| C3 | [`c3/s/squares_sequence.c3`](../../../c3/s/squares_sequence.c3) |
| C++ | [`cpp/s/squares_sequence.cpp`](../../../cpp/s/squares_sequence.cpp) |
| Elisa | [`elisa/s/squares_sequence.elisa`](../../../elisa/s/squares_sequence.elisa) |
| Nim | [`nim/s/squares_sequence.nim`](../../../nim/s/squares_sequence.nim) |
| Odin | [`odin/s/squares_sequence.odin`](../../../odin/s/squares_sequence.odin) |
| Rust | [`rust/s/squares_sequence.rs`](../../../rust/s/squares_sequence.rs) |
| V | [`v/s/squares_sequence.v`](../../../v/s/squares_sequence.v) |
| Zig | [`zig/s/squares_sequence.zig`](../../../zig/s/squares_sequence.zig) |

## TheAlgorithms reference

- [C# `SquaresSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/SquaresSequence.cs)
