# Project Euler Problem 800

## Contract

Input is two signed 64-bit integers, `[base, degree]`. Accept `2 <= base <= 1,000,000` and `1 <= degree <= 1,000,000`; other inputs return `-1`. The source computes `upper_bound = degree * log2(base)`, sieves primes strictly below `int(upper_bound)`, then counts pairs with its decreasing-right-pointer traversal and binary64 logarithms. The returned count follows that source traversal exactly, including its small-input pointer behavior.

The source examples return **2** for `(800, 1)` and **10,790** for `(800, 800)`. The default `(800800, 800800)` returns **1,412,403,576**.

## Workload

[`workload.json`](workload.json) includes the small source examples, the canonical default, a small-pointer behavior anchor, and invalid values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_800/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem800.c](../../../c/p/problem800.c) |
| C3 | [c3/p/problem800.c3](../../../c3/p/problem800.c3) |
| C++ | [cpp/p/problem800.cpp](../../../cpp/p/problem800.cpp) |
| Elisa | [elisa/p/problem800.elisa](../../../elisa/p/problem800.elisa) |
| Nim | [nim/p/problem800.nim](../../../nim/p/problem800.nim) |
| Odin | [odin/p/problem800.odin](../../../odin/p/problem800.odin) |
| Rust | [rust/p/problem800.rs](../../../rust/p/problem800.rs) |
| V | [v/p/problem800.v](../../../v/p/problem800.v) |
| Zig | [zig/p/problem800.zig](../../../zig/p/problem800.zig) |
