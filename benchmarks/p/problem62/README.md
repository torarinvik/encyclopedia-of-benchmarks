# Project Euler Problem 62: Cubic permutations

## Contract

The pinned Python source groups each cube by the sorted decimal digits of its value and returns the first cube in the first group to reach the requested size. The default is five members; this benchmark passes that default explicitly through the scalar ABI. The package accepts group sizes 1 through 5. Values outside that range return -1, since the benchmark's bounded input domain covers the source examples and default call.

Ports encode the sorted digits as packed decimal-digit nibbles with the digit count included, then use open addressing to preserve the source's insertion-order grouping. The source search reaches the requested group by base 8,384 for all supported group sizes, so the package uses that finite shared limit.

The no-argument source default returns 127,035,954,683 (5027 cubed). Its examples include solution(2) = 125 and solution(3) = 41,063,625.

## Workload

The [workload JSON](workload.json) covers group sizes 1 through 5, including the source examples and default, plus invalid values below and above the supported domain.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_062/sol1.py) stores cube bases under sorted digit signatures and returns the first base's cube when a group reaches the requested size.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem62.c](../../../c/p/problem62.c) |
| C3 | [c3/p/problem62.c3](../../../c3/p/problem62.c3) |
| C++ | [cpp/p/problem62.cpp](../../../cpp/p/problem62.cpp) |
| Elisa | [elisa/p/problem62.elisa](../../../elisa/p/problem62.elisa) |
| Nim | [nim/p/problem62.nim](../../../nim/p/problem62.nim) |
| Odin | [odin/p/problem62.odin](../../../odin/p/problem62.odin) |
| Rust | [rust/p/problem62.rs](../../../rust/p/problem62.rs) |
| V | [v/p/problem62.v](../../../v/p/problem62.v) |
| Zig | [zig/p/problem62.zig](../../../zig/p/problem62.zig) |
