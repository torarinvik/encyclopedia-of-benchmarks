# Powers of 10 sequence

## Contract

The input is a zero-based index `n` from 0 through 18. Return `10^n`, so the sequence begins `1, 10, 100, 1,000, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t powers_of10_sequence(int64_t index)`. Index 18 returns `10^18`, which fits signed 64-bit output; index 19 would return `10^19`, which does not. The ports preserve the source's repeated multiplication by ten.

## Source behavior and related sequences

The pinned C# generator initializes a `BigInteger` term to 1, yields it, and multiplies it by ten after every yield. The local contract therefore uses zero-based indexing with first term 1, rather than starting at 10.

`number_of_primes_by_powers_of10_sequence` is a distinct sequence: it counts primes across decimal power bands instead of returning the powers themselves.

## Workload

[`workload.json`](workload.json) covers the first powers, a middle term, the largest signed 64-bit term, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/powers_of10_sequence.c`](../../../c/p/powers_of10_sequence.c) |
| C3 | [`c3/p/powers_of10_sequence.c3`](../../../c3/p/powers_of10_sequence.c3) |
| C++ | [`cpp/p/powers_of10_sequence.cpp`](../../../cpp/p/powers_of10_sequence.cpp) |
| Elisa | [`elisa/p/powers_of10_sequence.elisa`](../../../elisa/p/powers_of10_sequence.elisa) |
| Nim | [`nim/p/powers_of10_sequence.nim`](../../../nim/p/powers_of10_sequence.nim) |
| Odin | [`odin/p/powers_of10_sequence.odin`](../../../odin/p/powers_of10_sequence.odin) |
| Rust | [`rust/p/powers_of10_sequence.rs`](../../../rust/p/powers_of10_sequence.rs) |
| V | [`v/p/powers_of10_sequence.v`](../../../v/p/powers_of10_sequence.v) |
| Zig | [`zig/p/powers_of10_sequence.zig`](../../../zig/p/powers_of10_sequence.zig) |

## TheAlgorithms reference

- [C# `PowersOf10Sequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PowersOf10Sequence.cs)
