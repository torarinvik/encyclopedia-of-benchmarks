# Negative integers sequence

## Contract

The input is a zero-based signed 64-bit index `n` from 0 through 9,223,372,036,854,775,807. Return `-n - 1`, producing the sequence `-1, -2, -3, ...` through `INT64_MIN`. Return 0 for negative indices. Zero is a safe invalid sentinel because no sequence term is zero.

The scalar ABI is `int64_t negative_integers_sequence(int64_t index)`. The expression `-index - 1` remains representable even at the largest supported index, where it returns `INT64_MIN`.

## Source behavior

The pinned C# generator initializes its `BigInteger` term to -1, yields the current term, and decrements it after each yield. The benchmark uses zero-based indexing, so input 0 selects the first yielded term.

This indexed contract measures direct term lookup. Advancing the source's lazy generator to index `n` takes O(n) iteration steps, while the ports compute the same term in O(1); the benchmark preserves sequence values, not generator iteration cost.

## Workload

[`workload.json`](workload.json) covers initial terms, a later index, both signed input boundaries, and the smallest signed 64-bit sequence term.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/negative_integers_sequence.c`](../../../c/n/negative_integers_sequence.c) |
| C3 | [`c3/n/negative_integers_sequence.c3`](../../../c3/n/negative_integers_sequence.c3) |
| C++ | [`cpp/n/negative_integers_sequence.cpp`](../../../cpp/n/negative_integers_sequence.cpp) |
| Elisa | [`elisa/n/negative_integers_sequence.elisa`](../../../elisa/n/negative_integers_sequence.elisa) |
| Nim | [`nim/n/negative_integers_sequence.nim`](../../../nim/n/negative_integers_sequence.nim) |
| Odin | [`odin/n/negative_integers_sequence.odin`](../../../odin/n/negative_integers_sequence.odin) |
| Rust | [`rust/n/negative_integers_sequence.rs`](../../../rust/n/negative_integers_sequence.rs) |
| V | [`v/n/negative_integers_sequence.v`](../../../v/n/negative_integers_sequence.v) |
| Zig | [`zig/n/negative_integers_sequence.zig`](../../../zig/n/negative_integers_sequence.zig) |

## TheAlgorithms reference

- [C# `NegativeIntegersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/NegativeIntegersSequence.cs)
