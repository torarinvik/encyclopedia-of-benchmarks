# Project Euler Problem 9

## Contract

For a total in `3..=1000`, find positive integers `a < b < c` such that `a + b + c == total` and `a² + b² == c²`, then return `a*b*c`. Return `-1` if the total is out of range or has no such triple.

The ports enumerate the feasible `a` and `b` values and derive `c` from the requested total. They use O(total²) time and O(1) extra space. The pinned Go and PHP programs solve the fixed total 1000; their canonical result is 31,875,000. They return zero when no triple is found, while this scalar contract uses `-1` as its no-solution sentinel.

## Workload

[`workload.json`](workload.json) covers the classic 3-4-5 and 5-12-13 triples, a total-120 example, the canonical total-1000 instance, and missing or invalid inputs.

## TheAlgorithms references

- Go [`Problem9`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_9/problem9.go) scans positive `a` and larger `b`, deriving `c` from the fixed total 1000.
- PHP [`Problem9.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem9.php) scans bounded `i` and `j` values and derives the remaining side for the same fixed total.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem9.c](../../../c/p/problem9.c) |
| C3 | [c3/p/problem9.c3](../../../c3/p/problem9.c3) |
| C++ | [cpp/p/problem9.cpp](../../../cpp/p/problem9.cpp) |
| Elisa | [elisa/p/problem9.elisa](../../../elisa/p/problem9.elisa) |
| Nim | [nim/p/problem9.nim](../../../nim/p/problem9.nim) |
| Odin | [odin/p/problem9.odin](../../../odin/p/problem9.odin) |
| Rust | [rust/p/problem9.rs](../../../rust/p/problem9.rs) |
| V | [v/p/problem9.v](../../../v/p/problem9.v) |
| Zig | [zig/p/problem9.zig](../../../zig/p/problem9.zig) |
