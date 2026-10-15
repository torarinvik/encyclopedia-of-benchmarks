# Golomb's sequence

## Contract

The input is a zero-based index `n` from 0 through 64. Return the corresponding term of Golomb's sequence, beginning `1, 2, 2, 3, 3, 4, 4, 4, 5, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t golombs_sequence(int64_t index)`. The bounded prefix fits comfortably in signed 64-bit values and needs at most 62 queue entries beyond the source's initial queue element. Each port uses a fixed queue sized for this contract and preserves the source generator's grouped enqueue-and-yield order.

## Source behavior and related sequences

The pinned C# generator yields `1, 2, 2`, seeds a FIFO queue with `2`, then for each increasing value `i` dequeues a repetition count and enqueues/yields `i` that many times. This produces the self-describing sequence in which each positive integer `i` appears `a(i)` times. The benchmark uses zero-based indexing into the yielded values.

This is distinct from the Kolakoski sequence, another self-describing sequence over runs, but with a different alphabet and recurrence.

## Workload

[`workload.json`](workload.json) covers the initial terms, later repetition groups, the largest supported index, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/golombs_sequence.c`](../../../c/g/golombs_sequence.c) |
| C3 | [`c3/g/golombs_sequence.c3`](../../../c3/g/golombs_sequence.c3) |
| C++ | [`cpp/g/golombs_sequence.cpp`](../../../cpp/g/golombs_sequence.cpp) |
| Elisa | [`elisa/g/golombs_sequence.elisa`](../../../elisa/g/golombs_sequence.elisa) |
| Nim | [`nim/g/golombs_sequence.nim`](../../../nim/g/golombs_sequence.nim) |
| Odin | [`odin/g/golombs_sequence.odin`](../../../odin/g/golombs_sequence.odin) |
| Rust | [`rust/g/golombs_sequence.rs`](../../../rust/g/golombs_sequence.rs) |
| V | [`v/g/golombs_sequence.v`](../../../v/g/golombs_sequence.v) |
| Zig | [`zig/g/golombs_sequence.zig`](../../../zig/g/golombs_sequence.zig) |

## TheAlgorithms reference

- [C# `GolombsSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/GolombsSequence.cs)
