# Project Euler Problem 203: Squarefree Binomial Coefficients

## Contract

Given a depth, return the sum of the distinct squarefree coefficients appearing in the first `depth` rows of Pascal's triangle. The pinned Python implementation starts with coefficient 1 and adds rows for `range(2, depth + 1)`, so depths below 2 (including negative depths) return 1. This benchmark supports depths through 51; larger inputs return -1 to keep the exact coefficients and sum within signed 64-bit arithmetic.

The ports preserve the source traversal: generate each row by adjacent sums, collect every coefficient, sort and deduplicate the values, then test each distinct value for repeated prime factors by trial division. The pinned source examples return 105 at depth 8 and 175 at depth 9. The canonical depth 51 result is **34029210557338**.

## Workload

[`workload.json`](workload.json) covers source edge behavior, the documented examples, the canonical depth, and the first unsupported depth.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_203/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem203.c](../../../c/p/problem203.c) |
| C3 | [c3/p/problem203.c3](../../../c3/p/problem203.c3) |
| C++ | [cpp/p/problem203.cpp](../../../cpp/p/problem203.cpp) |
| Elisa | [elisa/p/problem203.elisa](../../../elisa/p/problem203.elisa) |
| Nim | [nim/p/problem203.nim](../../../nim/p/problem203.nim) |
| Odin | [odin/p/problem203.odin](../../../odin/p/problem203.odin) |
| Rust | [rust/p/problem203.rs](../../../rust/p/problem203.rs) |
| V | [v/p/problem203.v](../../../v/p/problem203.v) |
| Zig | [zig/p/problem203.zig](../../../zig/p/problem203.zig) |
