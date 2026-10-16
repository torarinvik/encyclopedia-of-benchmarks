# Project Euler Problem 112: Bouncy numbers

## Contract

`problem112(percent)` returns the least positive integer at which the running proportion of bouncy numbers reaches the requested whole-number percentage. The workload supports integer percentages from 1 through 99; inputs outside that range return `-1`. The canonical 99% result is 1,587,000.

A positive integer is bouncy when its decimal digits are neither nondecreasing nor nonincreasing from left to right. The ports scan positive integers in ascending order, count bouncy values, and stop at the first `n` satisfying `bouncy_count * 100 >= percent * n`. This exact integer comparison matches the source for whole-number percentages and avoids floating-point threshold drift.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_112/sol1.py) identifies bouncy numbers by comparing the digit string with its sorted and reverse-sorted forms. Its `solution` accepts a percentage strictly between 0 and 100, increments `n` from 1, counts bouncy values, and returns when `(count / n) * 100 >= percent`. The package keeps this ascending search and first-reaching threshold rule. This scalar workload uses integer percentage targets, including the source examples, so the ratio check is equivalent without floating arithmetic.

## Workload

[`workload.json`](workload.json) includes 1%, 50%, 80%, 90%, and canonical 99% thresholds, plus invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem112.c](../../../c/p/problem112.c) |
| C3 | [c3/p/problem112.c3](../../../c3/p/problem112.c3) |
| C++ | [cpp/p/problem112.cpp](../../../cpp/p/problem112.cpp) |
| Elisa | [elisa/p/problem112.elisa](../../../elisa/p/problem112.elisa) |
| Nim | [nim/p/problem112.nim](../../../nim/p/problem112.nim) |
| Odin | [odin/p/problem112.odin](../../../odin/p/problem112.odin) |
| Rust | [rust/p/problem112.rs](../../../rust/p/problem112.rs) |
| V | [v/p/problem112.v](../../../v/p/problem112.v) |
| Zig | [zig/p/problem112.zig](../../../zig/p/problem112.zig) |
