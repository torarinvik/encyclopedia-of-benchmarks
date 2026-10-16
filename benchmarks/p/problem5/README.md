# Project Euler Problem 5

## Contract

Return the smallest positive integer evenly divisible by every integer from 1 through `limit`, where `limit` is in `1..=20`. Values outside that range return `-1`.

The shared ports build the least common multiple incrementally using Euclid's gcd, in O(limit log result) time and O(1) extra space. The pinned Go source searches candidate multiples starting at `limit * limit`, Haskell combines prime factorizations through 20, and PHP steps through multiples of 20 while testing divisors 11 through 20. Go's initial candidate is too large for limits 2 through 4, so it differs from the mathematical minimum on those generalized inputs; all three pinned sources match the shared contract at the canonical input `limit == 20`.

## Workload

[`workload.json`](workload.json) covers short ranges, the common below-10 and below-20 examples, the canonical result, and invalid bounds.

## TheAlgorithms references

- Go [`Problem5`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_5/problem5.go) scans integers beginning at `limit * limit` until it finds one divisible by every value through the parameter.
- Haskell [`Problem5.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem5/Problem5.hs) combines prime factors for the fixed upper bound 20.
- PHP [`Problem5.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem5.php) tests multiples of 20 against divisors 11 through 20.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem5.c](../../../c/p/problem5.c) |
| C3 | [c3/p/problem5.c3](../../../c3/p/problem5.c3) |
| C++ | [cpp/p/problem5.cpp](../../../cpp/p/problem5.cpp) |
| Elisa | [elisa/p/problem5.elisa](../../../elisa/p/problem5.elisa) |
| Nim | [nim/p/problem5.nim](../../../nim/p/problem5.nim) |
| Odin | [odin/p/problem5.odin](../../../odin/p/problem5.odin) |
| Rust | [rust/p/problem5.rs](../../../rust/p/problem5.rs) |
| V | [v/p/problem5.v](../../../v/p/problem5.v) |
| Zig | [zig/p/problem5.zig](../../../zig/p/problem5.zig) |
