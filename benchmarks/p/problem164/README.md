# Project Euler Problem 164

## Contract

For a digit count from 0 through 26, return the number of positive numbers with that many digits for which every three consecutive digits sum to at most 9. The first digit is 1 through 9; later digits are 0 through `9 - previous_digit - digit_before_previous`. The pinned source returns 1 for zero digits through its recursion base case. Inputs outside 0..26 return `-1` so counts fit signed 64-bit integers.

The ports preserve the source's digit-state recurrence with a small dynamic-programming table. The source examples return **45** for two digits and **21838806** for ten digits. Its 20-digit default returns **378158756814587**, and 26 is the largest supported digit count.

## Workload

[`workload.json`](workload.json) covers the empty base case, short lengths, source examples, the default, the maximum supported length, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_164/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem164.c](../../../c/p/problem164.c) |
| C3 | [c3/p/problem164.c3](../../../c3/p/problem164.c3) |
| C++ | [cpp/p/problem164.cpp](../../../cpp/p/problem164.cpp) |
| Elisa | [elisa/p/problem164.elisa](../../../elisa/p/problem164.elisa) |
| Nim | [nim/p/problem164.nim](../../../nim/p/problem164.nim) |
| Odin | [odin/p/problem164.odin](../../../odin/p/problem164.odin) |
| Rust | [rust/p/problem164.rs](../../../rust/p/problem164.rs) |
| V | [v/p/problem164.v](../../../v/p/problem164.v) |
| Zig | [zig/p/problem164.zig](../../../zig/p/problem164.zig) |
