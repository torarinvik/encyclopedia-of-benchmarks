# All twos sequence

## Contract

The input is a zero-based signed 64-bit index `n`. For every supported index `n >= 0`, return 2; return `-1` for a negative index. The sequence is `2, 2, 2, 2, ...` and has no mathematical upper index bound. This scalar benchmark accepts every nonnegative index representable by its `i64` input ABI.

The scalar ABI is `int64_t all_twos_sequence(int64_t index)`. The invalid sentinel `-1` cannot collide with a valid term, which is always 2.

## Source behavior

The pinned C# `ISequence` implementation yields the `BigInteger` value 2 forever. The benchmark uses zero-based indexing into that generator; the source's first yielded term is at index 0.

This indexed contract measures constant-time term lookup. The source itself exposes a lazy generator, so advancing it to index `n` takes O(n) iteration steps; the ports return the same indexed value directly in O(1). This package therefore preserves the sequence values, not the generator's iteration cost.

## Workload

[`workload.json`](workload.json) covers initial terms, later indices, the largest signed 64-bit index, and negative invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/all_twos_sequence.c`](../../../c/a/all_twos_sequence.c) |
| C3 | [`c3/a/all_twos_sequence.c3`](../../../c3/a/all_twos_sequence.c3) |
| C++ | [`cpp/a/all_twos_sequence.cpp`](../../../cpp/a/all_twos_sequence.cpp) |
| Elisa | [`elisa/a/all_twos_sequence.elisa`](../../../elisa/a/all_twos_sequence.elisa) |
| Nim | [`nim/a/all_twos_sequence.nim`](../../../nim/a/all_twos_sequence.nim) |
| Odin | [`odin/a/all_twos_sequence.odin`](../../../odin/a/all_twos_sequence.odin) |
| Rust | [`rust/a/all_twos_sequence.rs`](../../../rust/a/all_twos_sequence.rs) |
| V | [`v/a/all_twos_sequence.v`](../../../v/a/all_twos_sequence.v) |
| Zig | [`zig/a/all_twos_sequence.zig`](../../../zig/a/all_twos_sequence.zig) |

## TheAlgorithms reference

- [C# `AllTwosSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/AllTwosSequence.cs)
