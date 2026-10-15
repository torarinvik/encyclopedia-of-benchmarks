# Prime-pi sequence

## Contract

The input is a zero-based index `i` from 0 through 999. Return `π(i + 1)`, the count of primes less than or equal to `i + 1`. The sequence begins `0, 1, 2, 2, 3, 3, 4, ...`. Return `-1` outside the supported range.

The scalar ABI is `int64_t prime_pi_sequence(int64_t index)`. The workload stops at index 999 (`π(1000)=168`) to keep the pinned source's incremental prime generation practical.

## Source behavior and related sequences

The pinned C# `PrimePiSequence` starts its integer cursor at 0 and emits the count for n=1 first, then n=2, n=3, and so on. It consumes `PrimesSequence`, which starts with 2 and tests subsequent odd candidates against the primes already found. The benchmark maps zero-based term index `i` to `π(i+1)` and ports that incremental prime generation.

This differs from [`number_of_primes_by_powers_of10_sequence`](../../n/number_of_primes_by_powers_of10_sequence/README.md) and [`number_of_primes_by_number_of_digits_sequence`](../../n/number_of_primes_by_number_of_digits_sequence/README.md), which count primes in decimal-size bands, and from [`first_n_primes`](../../f/first_n_primes/README.md), which returns prime values rather than their cumulative count.

## Workload

[`workload.json`](workload.json) covers the first terms, a small prime count, the largest supported index, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/prime_pi_sequence.c`](../../../c/p/prime_pi_sequence.c) |
| C3 | [`c3/p/prime_pi_sequence.c3`](../../../c3/p/prime_pi_sequence.c3) |
| C++ | [`cpp/p/prime_pi_sequence.cpp`](../../../cpp/p/prime_pi_sequence.cpp) |
| Elisa | [`elisa/p/prime_pi_sequence.elisa`](../../../elisa/p/prime_pi_sequence.elisa) |
| Nim | [`nim/p/prime_pi_sequence.nim`](../../../nim/p/prime_pi_sequence.nim) |
| Odin | [`odin/p/prime_pi_sequence.odin`](../../../odin/p/prime_pi_sequence.odin) |
| Rust | [`rust/p/prime_pi_sequence.rs`](../../../rust/p/prime_pi_sequence.rs) |
| V | [`v/p/prime_pi_sequence.v`](../../../v/p/prime_pi_sequence.v) |
| Zig | [`zig/p/prime_pi_sequence.zig`](../../../zig/p/prime_pi_sequence.zig) |

## TheAlgorithms references

- [C# `PrimePiSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimePiSequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
