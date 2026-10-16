# Project Euler Problem 2

## Contract

Return the sum of the even Fibonacci terms strictly below `limit`, for the sequence beginning `1, 2, 3, 5, ...`. The scalar input is in `0..=4,000,000`; values outside that range return `-1`.

The ports use the Go source's iterative Fibonacci recurrence, taking O(log limit) time and O(1) extra space. Haskell and PHP solve the original fixed four-million instance. Their inclusive upper bound has the same result as the strict bound because no Fibonacci term equals 4,000,000.

## Workload

[`workload.json`](workload.json) covers low limits, strict boundaries around Fibonacci terms, the canonical Project Euler instance, and invalid bounds.

## TheAlgorithms references

- Go [`Problem2`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_2/problem2.go) starts with 1 and 2 and sums even terms below a caller-provided limit.
- Haskell [`Problem2.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem2/Problem2.hs) sums even terms up to the fixed four-million limit.
- PHP [`Problem2.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem2.php) computes the same fixed instance with an iterative recurrence.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem2.c](../../../c/p/problem2.c) |
| C3 | [c3/p/problem2.c3](../../../c3/p/problem2.c3) |
| C++ | [cpp/p/problem2.cpp](../../../cpp/p/problem2.cpp) |
| Elisa | [elisa/p/problem2.elisa](../../../elisa/p/problem2.elisa) |
| Nim | [nim/p/problem2.nim](../../../nim/p/problem2.nim) |
| Odin | [odin/p/problem2.odin](../../../odin/p/problem2.odin) |
| Rust | [rust/p/problem2.rs](../../../rust/p/problem2.rs) |
| V | [v/p/problem2.v](../../../v/p/problem2.v) |
| Zig | [zig/p/problem2.zig](../../../zig/p/problem2.zig) |
