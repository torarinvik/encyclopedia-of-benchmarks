# Divisors count sequence

## Contract

The input is a zero-based index `i` from 0 through 9,999. Return the number of positive divisors of `i + 1`; the sequence begins `1, 2, 2, 3, 2, 4, ...`. Return `-1` for negative indices and indices above 9,999.

The scalar ABI is `int64_t divisors_count_sequence(int64_t index)`. The bounded index keeps the pinned source's linear divisor scan practical. For each term after the first, the implementations start the count at 2 and test every divisor candidate from 2 through `n - 1`.

## Source behavior and related benchmark

The pinned C# generator yields 1 for n=1, then checks each integer from 2 up to n-1 and yields the resulting divisor count. Since the first term is for n=1, zero-based sequence index `i` maps to source value `n=i+1`.

[`number_of_positive_divisors`](../../n/number_of_positive_divisors/README.md) also counts divisors, but takes one signed integer in an array and uses factorization. This package preserves the source sequence index and linear scan.

## Workload

[`workload.json`](workload.json) covers initial terms, primes, perfect squares, a highly composite value, the maximum supported input, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/divisors_count_sequence.c`](../../../c/d/divisors_count_sequence.c) |
| C3 | [`c3/d/divisors_count_sequence.c3`](../../../c3/d/divisors_count_sequence.c3) |
| C++ | [`cpp/d/divisors_count_sequence.cpp`](../../../cpp/d/divisors_count_sequence.cpp) |
| Elisa | [`elisa/d/divisors_count_sequence.elisa`](../../../elisa/d/divisors_count_sequence.elisa) |
| Nim | [`nim/d/divisors_count_sequence.nim`](../../../nim/d/divisors_count_sequence.nim) |
| Odin | [`odin/d/divisors_count_sequence.odin`](../../../odin/d/divisors_count_sequence.odin) |
| Rust | [`rust/d/divisors_count_sequence.rs`](../../../rust/d/divisors_count_sequence.rs) |
| V | [`v/d/divisors_count_sequence.v`](../../../v/d/divisors_count_sequence.v) |
| Zig | [`zig/d/divisors_count_sequence.zig`](../../../zig/d/divisors_count_sequence.zig) |

## TheAlgorithms reference

- [C# `DivisorsCountSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/DivisorsCountSequence.cs)
