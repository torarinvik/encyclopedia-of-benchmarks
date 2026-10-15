# Sum of harmonic series

Sum terms whose reciprocals form an arithmetic progression. The pinned Python and Rust sources name the function sum_of_harmonic_progression; the benchmark keeps the catalog candidate name.

## Contract

- Inputs are first_term, common_difference, and number_of_terms as three binary64 values. The term count must be an integer from 1 to 256.
- Require 0 < first_term <= 1000 and 0 <= common_difference <= 1000. Invalid inputs return -1e300.
- Start with arithmetic_term = 1 / first_term. Add 1 / arithmetic_term for each term, advancing arithmetic_term by common_difference between terms. Accumulation follows input order.
- The bounds keep every divisor positive and all intermediate values finite. The algorithm uses O(n) time and O(1) auxiliary space.

## Pinned sources

The pinned [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sum_of_harmonic_series.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sum_of_harmonic_series.rs) implementations use the same recurrence. Both initialize the arithmetic progression with 1 / first_term, then append common_difference for each later term and sum the reciprocals.

## Workload and build

[workload.json](workload.json) covers both pinned examples, a single term, zero common difference, and invalid inputs. All nine ports use the float64_triple ABI family.

| Language | Source |
| --- | --- |
| C | [c/sum_of_harmonic_series.c](../../../c/s/sum_of_harmonic_series.c) |
| C3 | [c3/sum_of_harmonic_series.c3](../../../c3/s/sum_of_harmonic_series.c3) |
| C++ | [cpp/sum_of_harmonic_series.cpp](../../../cpp/s/sum_of_harmonic_series.cpp) |
| Elisa | [elisa/sum_of_harmonic_series.elisa](../../../elisa/s/sum_of_harmonic_series.elisa) |
| Nim | [nim/sum_of_harmonic_series.nim](../../../nim/s/sum_of_harmonic_series.nim) |
| Odin | [odin/sum_of_harmonic_series.odin](../../../odin/s/sum_of_harmonic_series.odin) |
| Rust | [rust/sum_of_harmonic_series.rs](../../../rust/s/sum_of_harmonic_series.rs) |
| V | [v/sum_of_harmonic_series.v](../../../v/s/sum_of_harmonic_series.v) |
| Zig | [zig/sum_of_harmonic_series.zig](../../../zig/s/sum_of_harmonic_series.zig) |
