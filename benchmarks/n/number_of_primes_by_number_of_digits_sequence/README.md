# Number of primes by number of digits sequence

## Contract

The input is a zero-based sequence index from `0` through `3`. Return the number of primes in the corresponding decimal digit band. Index `0` returns zero, preserving the pinned C# generator's initial term. For index `k >= 1`, the term counts primes `p` with `10^(k-1) < p <= 10^k`. Return `-1` outside the supported index range.

The scalar ABI is `int64_t number_of_primes_by_number_of_digits_sequence(int64_t index)`. The bounded sequence is `[0, 4, 21, 143]`. Each implementation counts primes in the requested band by trial division. The maximum upper endpoint is 1,000, so the complete call stays small and the trial-division bound uses `factor <= candidate / factor`.

## Source behavior and related benchmarks

The pinned C# `NumberOfPrimesByNumberOfDigitsSequence` streams `PrimesSequence` and counts primes while advancing a power-of-ten boundary. Its first prime, 2, exceeds the initial boundary 1, so the generator first yields an initial zero. Subsequent terms count the primes with one, two, and more decimal digits. The local contract preserves this zero term and bounds the index to 0..3.

This output is a sequence of counts for decimal digit bands. It differs from `prime_pi_sequence` and `linear_sieve`, which take an integer bound and return the count of all primes up to that bound. The digit-band terms can be computed as differences of prime-counting values, but they have a different input/output contract.

## Workload

[`workload.json`](workload.json) contains all four supported indices plus one value on each side of the domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_primes_by_number_of_digits_sequence.c`](../../../c/n/number_of_primes_by_number_of_digits_sequence.c) |
| C3 | [`c3/n/number_of_primes_by_number_of_digits_sequence.c3`](../../../c3/n/number_of_primes_by_number_of_digits_sequence.c3) |
| C++ | [`cpp/n/number_of_primes_by_number_of_digits_sequence.cpp`](../../../cpp/n/number_of_primes_by_number_of_digits_sequence.cpp) |
| Elisa | [`elisa/n/number_of_primes_by_number_of_digits_sequence.elisa`](../../../elisa/n/number_of_primes_by_number_of_digits_sequence.elisa) |
| Nim | [`nim/n/number_of_primes_by_number_of_digits_sequence.nim`](../../../nim/n/number_of_primes_by_number_of_digits_sequence.nim) |
| Odin | [`odin/n/number_of_primes_by_number_of_digits_sequence.odin`](../../../odin/n/number_of_primes_by_number_of_digits_sequence.odin) |
| Rust | [`rust/n/number_of_primes_by_number_of_digits_sequence.rs`](../../../rust/n/number_of_primes_by_number_of_digits_sequence.rs) |
| V | [`v/n/number_of_primes_by_number_of_digits_sequence.v`](../../../v/n/number_of_primes_by_number_of_digits_sequence.v) |
| Zig | [`zig/n/number_of_primes_by_number_of_digits_sequence.zig`](../../../zig/n/number_of_primes_by_number_of_digits_sequence.zig) |

## TheAlgorithms references

- [C# `NumberOfPrimesByNumberOfDigitsSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/NumberOfPrimesByNumberOfDigitsSequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
