# Project Euler Problem 7

## Contract

Return the `index`th prime, counting 2 as the first prime, for `index` in `1..=10,001`. Inputs outside that range return `-1`.

The ports enumerate candidate integers and use trial division through the square root to test primality. Runtime is O(p_index × sqrt(p_index)) in the worst case and extra space is O(1). The Go source uses optimized trial division for a caller-provided index. Haskell uses an infinite sieve and PHP counts primes through its fixed 10,001st-prime instance; both match the shared contract at `index == 10,001`.

## Workload

[`workload.json`](workload.json) covers the first primes, the sixth-prime example, a midrange index, the canonical 10,001st prime, and invalid bounds.

## TheAlgorithms references

- Go [`Problem7`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_7/problem7.go) counts primes found by its optimized trial-division helper.
- Haskell [`Problem7.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem7/Problem7.hs) takes the 10,001st item of an infinite sieve.
- PHP [`Problem7.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem7.php) counts primes up to the fixed 10,001st prime.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem7.c](../../../c/p/problem7.c) |
| C3 | [c3/p/problem7.c3](../../../c3/p/problem7.c3) |
| C++ | [cpp/p/problem7.cpp](../../../cpp/p/problem7.cpp) |
| Elisa | [elisa/p/problem7.elisa](../../../elisa/p/problem7.elisa) |
| Nim | [nim/p/problem7.nim](../../../nim/p/problem7.nim) |
| Odin | [odin/p/problem7.odin](../../../odin/p/problem7.odin) |
| Rust | [rust/p/problem7.rs](../../../rust/p/problem7.rs) |
| V | [v/p/problem7.v](../../../v/p/problem7.v) |
| Zig | [zig/p/problem7.zig](../../../zig/p/problem7.zig) |
