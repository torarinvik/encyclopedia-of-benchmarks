# Project Euler Problem 31: Recursive Coin Sums

## Contract

For a target of `0..=200` pence, count unordered combinations of any number of the standard UK coins `[1, 2, 5, 10, 20, 50, 100, 200]` that sum to the target. The empty combination counts as the single way to make zero. Targets outside the range return `-1`.

The ports preserve the un-memoized recurrence from the pinned recursive source. For coin `c` and current amount `n`, the recurrence adds the counts for `(n - c, c)` and `(n, next smaller coin)`; a negative amount contributes zero, and the 1-pence-only base contributes one way for every nonnegative amount. This repeatedly explores the same subproblems, so this benchmark caps the target at the canonical 200 pence. The separate [`problem31`](../problem31/README.md) benchmark preserves the bottom-up dynamic-programming variant and covers targets through 500.

## Workload

[`workload.json`](workload.json) covers zero and small targets, the source examples at 10, 50, and 200 pence, 100 pence, and invalid bounds. The canonical 200-pence answer is 73,682.

## TheAlgorithms references

- Project Euler [Problem 31](https://projecteuler.net/problem=31) defines the eight UK coin denominations.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_031/sol1.py) defines the recursive chain from 1-pence through 2-pound coins, and documents 10→11, 50→451, 200→73,682, and 500→6,295,434. This benchmark preserves its recurrence through the canonical target; its domain is deliberately capped at 200 to bound the un-memoized expansion.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem31_recursive.c](../../../c/p/problem31_recursive.c) |
| C3 | [c3/p/problem31_recursive.c3](../../../c3/p/problem31_recursive.c3) |
| C++ | [cpp/p/problem31_recursive.cpp](../../../cpp/p/problem31_recursive.cpp) |
| Elisa | [elisa/p/problem31_recursive.elisa](../../../elisa/p/problem31_recursive.elisa) |
| Nim | [nim/p/problem31_recursive.nim](../../../nim/p/problem31_recursive.nim) |
| Odin | [odin/p/problem31_recursive.odin](../../../odin/p/problem31_recursive.odin) |
| Rust | [rust/p/problem31_recursive.rs](../../../rust/p/problem31_recursive.rs) |
| V | [v/p/problem31_recursive.v](../../../v/p/problem31_recursive.v) |
| Zig | [zig/p/problem31_recursive.zig](../../../zig/p/problem31_recursive.zig) |
