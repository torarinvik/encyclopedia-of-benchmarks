# Number of primes by powers of 10 sequence

## Contract

The input is a zero-based sequence index from 0 through 3. Return `[0, 4, 25, 168][index]`: the source's initial zero, followed by the cumulative number of primes less than 10, 100, and 1,000. Return `-1` outside the supported range.

The scalar ABI is `int64_t number_of_primes_by_powers_of10_sequence(int64_t index)`. The bound keeps prime enumeration through 1,000 small. The ports count candidates by trial division, using the overflow-safe condition `factor <= value / factor`.

## Source behavior and related sequences

The pinned C# generator creates `PrimesSequence`, starts its threshold at 1 and count at 0, and yields the count whenever the next prime is greater than the current threshold. Since its first prime is 2, it first yields 0 at the threshold 1. It then advances thresholds by powers of ten, producing 4, 25, and 168. The count is cumulative: it includes every prime below each threshold.

This differs from `number_of_primes_by_number_of_digits_sequence`, which counts only the primes in each decimal digit band and yields `[0, 4, 21, 143]`. The cumulative terms here equal the prime-counting function at selected powers of ten, rather than the individual band counts.

## Workload

[`workload.json`](workload.json) covers the initial term, all supported power-of-ten boundaries, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_primes_by_powers_of10_sequence.c`](../../../c/n/number_of_primes_by_powers_of10_sequence.c) |
| C3 | [`c3/n/number_of_primes_by_powers_of10_sequence.c3`](../../../c3/n/number_of_primes_by_powers_of10_sequence.c3) |
| C++ | [`cpp/n/number_of_primes_by_powers_of10_sequence.cpp`](../../../cpp/n/number_of_primes_by_powers_of10_sequence.cpp) |
| Elisa | [`elisa/n/number_of_primes_by_powers_of10_sequence.elisa`](../../../elisa/n/number_of_primes_by_powers_of10_sequence.elisa) |
| Nim | [`nim/n/number_of_primes_by_powers_of10_sequence.nim`](../../../nim/n/number_of_primes_by_powers_of10_sequence.nim) |
| Odin | [`odin/n/number_of_primes_by_powers_of10_sequence.odin`](../../../odin/n/number_of_primes_by_powers_of10_sequence.odin) |
| Rust | [`rust/n/number_of_primes_by_powers_of10_sequence.rs`](../../../rust/n/number_of_primes_by_powers_of10_sequence.rs) |
| V | [`v/n/number_of_primes_by_powers_of10_sequence.v`](../../../v/n/number_of_primes_by_powers_of10_sequence.v) |
| Zig | [`zig/n/number_of_primes_by_powers_of10_sequence.zig`](../../../zig/n/number_of_primes_by_powers_of10_sequence.zig) |

## TheAlgorithms references

- [C# `NumberOfPrimesByPowersOf10Sequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/NumberOfPrimesByPowersOf10Sequence.cs)
- [C# `PrimesSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/PrimesSequence.cs)
