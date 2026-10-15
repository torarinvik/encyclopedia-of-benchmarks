# Fermat numbers sequence

## Contract

The input is a zero-based index from `0` through `5`. Return the Fermat number

```text
F(n) = 2^(2^n) + 1
```

The sequence is `3, 5, 17, 257, 65537, 4294967297`. Return `-1` outside the supported range.

The scalar ABI is `int64_t fermat_numbers_sequence(int64_t index)`. The pinned C# source repeatedly squares a `BigInteger` initialized to 2 and returns the current value plus one. The local ports preserve that repeated-squaring progression. Index 5 is the largest term that fits signed 64-bit output; index 6 is `2^64 + 1` and exceeds the shared result type.

## Source behavior and related candidates

`FermatNumbersSequence` is infinite and has no invalid-input behavior; the bounded scalar contract maps indices outside 0..5 to `-1`. The sibling `FermatPrimesSequence` takes only the first five Fermat numbers. This benchmark covers the full Fermat-number sequence through index 5, including `F(5)=4294967297`, which is composite. A Fermat number is not guaranteed to be prime.

## Workload

[`workload.json`](workload.json) covers the first terms, a later term, the largest supported result, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fermat_numbers_sequence.c`](../../../c/f/fermat_numbers_sequence.c) |
| C3 | [`c3/f/fermat_numbers_sequence.c3`](../../../c3/f/fermat_numbers_sequence.c3) |
| C++ | [`cpp/f/fermat_numbers_sequence.cpp`](../../../cpp/f/fermat_numbers_sequence.cpp) |
| Elisa | [`elisa/f/fermat_numbers_sequence.elisa`](../../../elisa/f/fermat_numbers_sequence.elisa) |
| Nim | [`nim/f/fermat_numbers_sequence.nim`](../../../nim/f/fermat_numbers_sequence.nim) |
| Odin | [`odin/f/fermat_numbers_sequence.odin`](../../../odin/f/fermat_numbers_sequence.odin) |
| Rust | [`rust/f/fermat_numbers_sequence.rs`](../../../rust/f/fermat_numbers_sequence.rs) |
| V | [`v/f/fermat_numbers_sequence.v`](../../../v/f/fermat_numbers_sequence.v) |
| Zig | [`zig/f/fermat_numbers_sequence.zig`](../../../zig/f/fermat_numbers_sequence.zig) |

## TheAlgorithms references

- [C# `FermatNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/FermatNumbersSequence.cs)
- [C# `FermatPrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/FermatPrimesSequence.cs)
