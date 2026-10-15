# Zero sequence

## Contract

The input is a zero-based signed 64-bit index `n`. For every supported index `n >= 0`, return 0; return `-1` for a negative index. The sequence is `0, 0, 0, 0, ...` and has no mathematical upper index bound. This scalar benchmark accepts every nonnegative index representable by its `i64` input ABI.

The scalar ABI is `int64_t zero_sequence(int64_t index)`. The invalid sentinel `-1` cannot collide with a valid term, which is always 0.

## Source behavior

The pinned C# `ISequence` implementation yields the `BigInteger` value 0 forever. The benchmark uses zero-based indexing into that generator; the source's first yielded term is at index 0.

This indexed contract measures constant-time term lookup. The source itself exposes a lazy generator, so advancing it to index `n` takes O(n) iteration steps; the ports return the same indexed value directly in O(1). This package therefore preserves the sequence values, not the generator's iteration cost.

## Workload

[`workload.json`](workload.json) covers initial terms, later indices, the largest signed 64-bit index, and negative invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/z/zero_sequence.c`](../../../c/z/zero_sequence.c) |
| C3 | [`c3/z/zero_sequence.c3`](../../../c3/z/zero_sequence.c3) |
| C++ | [`cpp/z/zero_sequence.cpp`](../../../cpp/z/zero_sequence.cpp) |
| Elisa | [`elisa/z/zero_sequence.elisa`](../../../elisa/z/zero_sequence.elisa) |
| Nim | [`nim/z/zero_sequence.nim`](../../../nim/z/zero_sequence.nim) |
| Odin | [`odin/z/zero_sequence.odin`](../../../odin/z/zero_sequence.odin) |
| Rust | [`rust/z/zero_sequence.rs`](../../../rust/z/zero_sequence.rs) |
| V | [`v/z/zero_sequence.v`](../../../v/z/zero_sequence.v) |
| Zig | [`zig/z/zero_sequence.zig`](../../../zig/z/zero_sequence.zig) |

## TheAlgorithms reference

- [C# `ZeroSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/ZeroSequence.cs)
