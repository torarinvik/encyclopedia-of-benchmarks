# Natural sequence

## Contract

The input is a zero-based index `n` from 0 through 9,223,372,036,854,775,806. Return the natural-number term `n + 1`; the sequence begins `1, 2, 3, 4, ...`. Return `-1` for negative indices and for index 9,223,372,036,854,775,807, whose term would exceed signed 64-bit output.

The scalar ABI is `int64_t natural_sequence(int64_t index)`. The largest supported index returns `INT64_MAX`; the invalid sentinel `-1` cannot collide with a valid term.

## Source behavior

The pinned C# generator initializes a `BigInteger` value to 1, yields it, and increments it after each yield. The benchmark uses zero-based indexing into the generator, so input 0 selects its first term.

This indexed contract measures direct term lookup. Advancing the source's lazy generator to index `n` takes O(n) iteration steps, while the ports return the same term in O(1); the benchmark preserves sequence values, not generator iteration cost.

## Workload

[`workload.json`](workload.json) covers the first terms, a middle term, the largest signed 64-bit result, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/natural_sequence.c`](../../../c/n/natural_sequence.c) |
| C3 | [`c3/n/natural_sequence.c3`](../../../c3/n/natural_sequence.c3) |
| C++ | [`cpp/n/natural_sequence.cpp`](../../../cpp/n/natural_sequence.cpp) |
| Elisa | [`elisa/n/natural_sequence.elisa`](../../../elisa/n/natural_sequence.elisa) |
| Nim | [`nim/n/natural_sequence.nim`](../../../nim/n/natural_sequence.nim) |
| Odin | [`odin/n/natural_sequence.odin`](../../../odin/n/natural_sequence.odin) |
| Rust | [`rust/n/natural_sequence.rs`](../../../rust/n/natural_sequence.rs) |
| V | [`v/n/natural_sequence.v`](../../../v/n/natural_sequence.v) |
| Zig | [`zig/n/natural_sequence.zig`](../../../zig/n/natural_sequence.zig) |

## TheAlgorithms reference

- [C# `NaturalSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/NaturalSequence.cs)
