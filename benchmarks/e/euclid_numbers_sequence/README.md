# Euclid numbers sequence

## Contract

The input is a zero-based index `n` from 0 through 15. Return one plus the product of the first `n + 1` primes. The sequence begins `2, 3, 7, 31, 211, ...`. Return `-1` outside the supported index range.

The scalar ABI is `int64_t euclid_numbers_sequence(int64_t index)`. The upper bound is the largest index whose term fits signed 64-bit output: index 15 uses the first 16 primes through 47 and returns `614889782588491411`; the next term exceeds `INT64_MAX`. Implementations enumerate primes in ascending order and multiply the first `index + 1` values, then add one, preserving the pinned sequence construction.

## Source behavior and related sequences

The pinned C# `EuclidNumbersSequence` yields `n + 1` for each item of `PrimorialNumbersSequence`. That primorial source emits the empty product 1 first, then multiplies successive primes, so the first Euclid number is 2. The local scalar contract uses a zero-based index into this infinite source sequence and bounds it to 0..15 for signed 64-bit output.

This is different from `sylvester_sequence`: both begin with 2, 3, and 7, but Euclid numbers are one plus primorials, while Sylvester terms recursively add one to the product of all previous terms (the next Sylvester term is 43; the next Euclid number is 31). The sequence is also distinct from the primorial sequence itself, whose terms are the unincremented products.

## Workload

[`workload.json`](workload.json) covers the first terms, later terms, the largest supported value, and invalid indices on either side of the domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/euclid_numbers_sequence.c`](../../../c/e/euclid_numbers_sequence.c) |
| C3 | [`c3/e/euclid_numbers_sequence.c3`](../../../c3/e/euclid_numbers_sequence.c3) |
| C++ | [`cpp/e/euclid_numbers_sequence.cpp`](../../../cpp/e/euclid_numbers_sequence.cpp) |
| Elisa | [`elisa/e/euclid_numbers_sequence.elisa`](../../../elisa/e/euclid_numbers_sequence.elisa) |
| Nim | [`nim/e/euclid_numbers_sequence.nim`](../../../nim/e/euclid_numbers_sequence.nim) |
| Odin | [`odin/e/euclid_numbers_sequence.odin`](../../../odin/e/euclid_numbers_sequence.odin) |
| Rust | [`rust/e/euclid_numbers_sequence.rs`](../../../rust/e/euclid_numbers_sequence.rs) |
| V | [`v/e/euclid_numbers_sequence.v`](../../../v/e/euclid_numbers_sequence.v) |
| Zig | [`zig/e/euclid_numbers_sequence.zig`](../../../zig/e/euclid_numbers_sequence.zig) |

## TheAlgorithms references

- [C# `EuclidNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/EuclidNumbersSequence.cs)
- [C# `PrimorialNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimorialNumbersSequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
