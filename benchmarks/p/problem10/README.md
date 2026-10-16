# Project Euler Problem 10

## Contract

Return the sum of all prime numbers strictly below `limit`, for `limit` in `0..=2,000,000`. Values outside that range return `-1`.

The ports use an odd-only Sieve of Eratosthenes, in O(limit log log limit) time and O(limit) boolean flags of space. The Go source exposes a bound and calls its prime sieve; PHP sieves through its fixed bound of two million, including the endpoint. The shared contract is strict below the bound; the sources match it at the canonical input because 2,000,000 is composite.

## Workload

[`workload.json`](workload.json) covers empty and small bounds, the examples below 10 and 1,000, the canonical two-million limit, and invalid bounds. Because the canonical sieve allocates a million odd-entry flags, the measurement uses one repetition per sample.

## TheAlgorithms references

- Go [`Problem10`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_10/problem10.go) sums the result of its Sieve of Eratosthenes helper for a caller-provided bound.
- PHP [`Problem10.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem10.php) sieves through 2,000,000 and sums the surviving values.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem10.c](../../../c/p/problem10.c) |
| C3 | [c3/p/problem10.c3](../../../c3/p/problem10.c3) |
| C++ | [cpp/p/problem10.cpp](../../../cpp/p/problem10.cpp) |
| Elisa | [elisa/p/problem10.elisa](../../../elisa/p/problem10.elisa) |
| Nim | [nim/p/problem10.nim](../../../nim/p/problem10.nim) |
| Odin | [odin/p/problem10.odin](../../../odin/p/problem10.odin) |
| Rust | [rust/p/problem10.rs](../../../rust/p/problem10.rs) |
| V | [v/p/problem10.v](../../../v/p/problem10.v) |
| Zig | [zig/p/problem10.zig](../../../zig/p/problem10.zig) |
