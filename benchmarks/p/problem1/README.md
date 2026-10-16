# Project Euler Problem 1

## Contract

Return the sum of all positive integers strictly below `limit` that are divisible by 3 or 5. The scalar input is in `0..=100,000`; values outside that range return `-1`. The loop includes each qualifying integer once even when it is divisible by both 3 and 5.

The ports use the source Go implementation's direct scan, which takes O(limit) time and O(1) extra space. The bound keeps the sum below signed 64-bit overflow. Haskell and PHP solve the original fixed Project Euler instance for values below 1,000; their exact overlap with this parameterized contract is `limit == 1000`.

## Workload

[`workload.json`](workload.json) covers small limits, strict-boundary behavior, the canonical below-1,000 answer, the maximum supported input, and invalid bounds.

## TheAlgorithms references

- Go [`Problem1`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_1/problem1.go) scans values below a caller-provided limit.
- Haskell [`Problem1.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem1/Problem1.hs) filters the fixed range 1 through 999.
- PHP [`Problem1.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem1.php) provides two implementations over the same fixed below-1,000 range.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem1.c](../../../c/p/problem1.c) |
| C3 | [c3/p/problem1.c3](../../../c3/p/problem1.c3) |
| C++ | [cpp/p/problem1.cpp](../../../cpp/p/problem1.cpp) |
| Elisa | [elisa/p/problem1.elisa](../../../elisa/p/problem1.elisa) |
| Nim | [nim/p/problem1.nim](../../../nim/p/problem1.nim) |
| Odin | [odin/p/problem1.odin](../../../odin/p/problem1.odin) |
| Rust | [rust/p/problem1.rs](../../../rust/p/problem1.rs) |
| V | [v/p/problem1.v](../../../v/p/problem1.v) |
| Zig | [zig/p/problem1.zig](../../../zig/p/problem1.zig) |
