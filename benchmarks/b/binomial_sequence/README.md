# Binomial sequence

## Contract

The input is a zero-based index from 0 through 230. Return the coefficient at that position when Pascal rows are flattened in order, starting with row 0. The sequence begins `1, 1, 1, 1, 2, 1, 1, 3, 3, 1, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t binomial_sequence(int64_t index)`. Index 230 is the last coefficient in row 20. The benchmark stops after row 20 to keep the pinned source's recursive coefficient calculation practical; all coefficients in that prefix fit signed 64-bit output.

## Source behavior and related benchmark

The pinned C# generator builds row 0, then row 1, then each following row, yielding coefficients from left to right. Its coefficient helper uses `C(n,k)=C(n-1,k)+C(n-1,k-1)` with endpoint coefficients equal to 1. The benchmark maps a flattened sequence index back to its Pascal row and column, then preserves that recurrence.

[`binomial_coefficient`](../binomial_coefficient/README.md) accepts `(n,k)` directly. This package instead accepts one index into the flattened sequence.

## Workload

[`workload.json`](workload.json) covers row boundaries, interior coefficients, the largest supported index, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binomial_sequence.c`](../../../c/b/binomial_sequence.c) |
| C3 | [`c3/b/binomial_sequence.c3`](../../../c3/b/binomial_sequence.c3) |
| C++ | [`cpp/b/binomial_sequence.cpp`](../../../cpp/b/binomial_sequence.cpp) |
| Elisa | [`elisa/b/binomial_sequence.elisa`](../../../elisa/b/binomial_sequence.elisa) |
| Nim | [`nim/b/binomial_sequence.nim`](../../../nim/b/binomial_sequence.nim) |
| Odin | [`odin/b/binomial_sequence.odin`](../../../odin/b/binomial_sequence.odin) |
| Rust | [`rust/b/binomial_sequence.rs`](../../../rust/b/binomial_sequence.rs) |
| V | [`v/b/binomial_sequence.v`](../../../v/b/binomial_sequence.v) |
| Zig | [`zig/b/binomial_sequence.zig`](../../../zig/b/binomial_sequence.zig) |

## TheAlgorithms reference

- [C# `BinomialSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/BinomialSequence.cs)
