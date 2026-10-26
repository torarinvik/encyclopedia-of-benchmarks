# Project Euler Problem 6

## Contract

For `limit` in `0..=100`, return the square of the sum of integers from 1 through `limit`, minus the sum of their squares. The empty range at zero returns zero. Values outside the range return `-1`.

The ports use the source Go implementation's direct scan in O(limit) time and O(1) extra space. Haskell computes the fixed range through 100; PHP and Go accept a range bound. All three match the shared contract at `limit == 100`.

## Workload

[`workload.json`](workload.json) covers the empty range, small examples, the ten-number example, the canonical one-hundred input, and invalid bounds.

## TheAlgorithms references

- Go [`Problem6`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_6/problem6.go) accumulates the running sum and sum of squares up to its input.
- Haskell [`Problem6.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem6/Problem6.hs) computes the same difference for the fixed range 1 through 100.
- PHP [`Problem6.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem6.php) accumulates the values through a configurable inclusive maximum.
- C [`sol.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_6/sol.c) uses the same direct sum and sum-of-squares loops for the fixed 1..100 input; it aliases this package.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem6.c](../../../c/p/problem6.c) |
| C3 | [c3/p/problem6.c3](../../../c3/p/problem6.c3) |
| C++ | [cpp/p/problem6.cpp](../../../cpp/p/problem6.cpp) |
| Elisa | [elisa/p/problem6.elisa](../../../elisa/p/problem6.elisa) |
| Nim | [nim/p/problem6.nim](../../../nim/p/problem6.nim) |
| Odin | [odin/p/problem6.odin](../../../odin/p/problem6.odin) |
| Rust | [rust/p/problem6.rs](../../../rust/p/problem6.rs) |
| V | [v/p/problem6.v](../../../v/p/problem6.v) |
| Zig | [zig/p/problem6.zig](../../../zig/p/problem6.zig) |
