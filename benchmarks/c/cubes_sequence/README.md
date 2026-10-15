# Cubes sequence

## Contract

The input is a zero-based index `n` from 0 through 2,097,151. Return `n³`, so the sequence begins `0, 1, 8, 27, 64, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t cubes_sequence(int64_t index)`. The upper bound is the largest nonnegative index whose cube fits in signed 64-bit output: `2,097,151³` is `9,223,358,842,721,533,951`, while `2,097,152³` is `2⁶³` and does not fit. The ports compute the same direct cube as the source.

## Source behavior and related algorithms

The pinned C# iterator initializes a `BigInteger` counter to zero, yields its cube, then increments the counter. The local scalar contract uses the zero-based index of that infinite sequence and bounds the result to signed 64-bit range.

This returns a cube value. It is different from `perfect_cube`, which checks whether an input is an integer cube and returns a predicate result.

## Workload

[`workload.json`](workload.json) covers the first terms, a large supported index, the signed 64-bit boundary, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cubes_sequence.c`](../../../c/c/cubes_sequence.c) |
| C3 | [`c3/c/cubes_sequence.c3`](../../../c3/c/cubes_sequence.c3) |
| C++ | [`cpp/c/cubes_sequence.cpp`](../../../cpp/c/cubes_sequence.cpp) |
| Elisa | [`elisa/c/cubes_sequence.elisa`](../../../elisa/c/cubes_sequence.elisa) |
| Nim | [`nim/c/cubes_sequence.nim`](../../../nim/c/cubes_sequence.nim) |
| Odin | [`odin/c/cubes_sequence.odin`](../../../odin/c/cubes_sequence.odin) |
| Rust | [`rust/c/cubes_sequence.rs`](../../../rust/c/cubes_sequence.rs) |
| V | [`v/c/cubes_sequence.v`](../../../v/c/cubes_sequence.v) |
| Zig | [`zig/c/cubes_sequence.zig`](../../../zig/c/cubes_sequence.zig) |

## TheAlgorithms reference

- [C# `CubesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/CubesSequence.cs)
