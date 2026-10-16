# Project Euler Problem 113: Non-bouncy numbers

## Contract

For each digit length `i` from 1 through `num_digits`, the pinned source computes `choose(8+i, i) + choose(9+i, i) - 10` and sums the results. This yields the number of positive non-bouncy integers below `10^num_digits`. The source's `choose` uses a floating multiplicative recurrence and rounds its result; integer binomial recurrence gives the same values throughout this benchmark's supported positive range.

The benchmark supports `num_digits` through 100 and returns -1 above that bound. Nonpositive inputs return 0 because the source loop over `range(1, num_digits + 1)` is empty. The source default is 100 and returns 51,161,058,134,250; examples return 12,951 for 6 digits and 277,032 for 10 digits.

## Workload

The [workload JSON](workload.json) covers nonpositive bounds, the source examples and default, and the first unsupported positive value.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_113/sol1.py) sums its binomial non-bouncy count for every digit length from 1 through the requested bound.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem113.c](../../../c/p/problem113.c) |
| C3 | [c3/p/problem113.c3](../../../c3/p/problem113.c3) |
| C++ | [cpp/p/problem113.cpp](../../../cpp/p/problem113.cpp) |
| Elisa | [elisa/p/problem113.elisa](../../../elisa/p/problem113.elisa) |
| Nim | [nim/p/problem113.nim](../../../nim/p/problem113.nim) |
| Odin | [odin/p/problem113.odin](../../../odin/p/problem113.odin) |
| Rust | [rust/p/problem113.rs](../../../rust/p/problem113.rs) |
| V | [v/p/problem113.v](../../../v/p/problem113.v) |
| Zig | [zig/p/problem113.zig](../../../zig/p/problem113.zig) |
