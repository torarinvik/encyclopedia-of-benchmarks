# Project Euler Problem 31: Coin Sums

## Contract

For a target of `0..=500` pence, count the unordered combinations of any number of the standard UK coins `[1, 2, 5, 10, 20, 50, 100, 200]` that sum to the target. The empty combination counts as the single way to make zero. Targets outside the range return `-1`.

The ports use bottom-up unbounded-coin dynamic programming. Processing denominations in ascending order and amounts from each coin value upward counts combinations without treating different coin orders as different ways. The 500-pence cap includes the upper example in the pinned Python sources and keeps the benchmark's state small.

## Workload

[`workload.json`](workload.json) covers zero and small amounts, the source examples at 10, 50, 200, and 500 pence, an intermediate 100-pence case, and invalid bounds. The canonical Project Euler answer is 73,682 ways to make 200 pence.

## TheAlgorithms references

- Project Euler [Problem 31](https://projecteuler.net/problem=31) defines the eight denominations and asks for the number of ways to make £2.
- Python [`sol2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_031/sol2.py) uses bottom-up dynamic programming over the same denominations and documents 10→11, 50→451, 200→73,682, and 500→6,295,434.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_031/sol1.py) uses un-memoized recursive recurrences; that strategy is preserved separately in [`problem31_recursive`](../problem31_recursive/README.md).

The source functions accept nonnegative targets and do not share a validation convention for negative inputs, so this benchmark returns `-1` outside its explicit target range.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem31.c](../../../c/p/problem31.c) |
| C3 | [c3/p/problem31.c3](../../../c3/p/problem31.c3) |
| C++ | [cpp/p/problem31.cpp](../../../cpp/p/problem31.cpp) |
| Elisa | [elisa/p/problem31.elisa](../../../elisa/p/problem31.elisa) |
| Nim | [nim/p/problem31.nim](../../../nim/p/problem31.nim) |
| Odin | [odin/p/problem31.odin](../../../odin/p/problem31.odin) |
| Rust | [rust/p/problem31.rs](../../../rust/p/problem31.rs) |
| V | [v/p/problem31.v](../../../v/p/problem31.v) |
| Zig | [zig/p/problem31.zig](../../../zig/p/problem31.zig) |
