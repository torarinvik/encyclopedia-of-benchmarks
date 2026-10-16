# Project Euler Problem 180: golden triples

## Contract

For an order from 1 through 35, return the numerator plus denominator of the reduced sum of all distinct values `x + y + z` for golden triples. Each of `x`, `y`, and `z` must be a positive proper rational with denominator at most the order. Values outside the benchmark domain return `-1`.

The pinned source reduces the condition to testing the four equations `x + y = z`, `x² + y² = z²`, `1/x + 1/y = 1/z`, and `1/x² + 1/y² = 1/z²`. A candidate `z` is retained only after reduction when `0 < z < 1` and its denominator is at most the order. Each `x + y + z` fraction is reduced and deduplicated before the total is formed.

The ports preserve that exact rational behavior. They enumerate reduced `x` and `y` values once per rational pair (the source also visits equivalent unreduced representations), and use symmetry in `x` and `y` to avoid duplicate pair work. Square checks and roots use integer arithmetic. The final sum uses a common denominator and an exact small-limb accumulator, then reduces the total fraction before returning `u + v`.

The source examples return **296** for order 5, **12,519** for order 10, and **19,408,891,927** for order 20. The order 35 result is **285,196,020,571,078,987**.

The pinned file path identifies Problem 180; its module docstring mistakenly labels the statement as Problem 234.

## Workload

[`workload.json`](workload.json) covers source examples, the canonical order, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_180/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem180.c](../../../c/p/problem180.c) |
| C3 | [c3/p/problem180.c3](../../../c3/p/problem180.c3) |
| C++ | [cpp/p/problem180.cpp](../../../cpp/p/problem180.cpp) |
| Elisa | [elisa/p/problem180.elisa](../../../elisa/p/problem180.elisa) |
| Nim | [nim/p/problem180.nim](../../../nim/p/problem180.nim) |
| Odin | [odin/p/problem180.odin](../../../odin/p/problem180.odin) |
| Rust | [rust/p/problem180.rs](../../../rust/p/problem180.rs) |
| V | [v/p/problem180.v](../../../v/p/problem180.v) |
| Zig | [zig/p/problem180.zig](../../../zig/p/problem180.zig) |
