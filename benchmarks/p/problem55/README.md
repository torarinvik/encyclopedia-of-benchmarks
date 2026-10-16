# Project Euler Problem 55: Lychrel Numbers

## Contract

For an exclusive limit of `0..=10,000`, count each starting integer `n` in `1 <= n < limit` that has not produced a palindrome after 50 reverse-and-add iterations. Each iteration first computes `n + reverse(n)` and then checks the result for palindromicity. The starting value itself is not checked before its first addition. Limits outside the range return `-1`.

The ports use a fixed 64-digit decimal buffer to perform exact reverse-and-add arithmetic without a language-specific big-integer dependency. Four initial digits plus at most one added digit per iteration fit within the buffer for the 50-step bound.

## Workload

[`workload.json`](workload.json) covers empty and small exclusive ranges, the source examples at limits 1,000, 5,000, and 10,000, and invalid bounds. The canonical count below 10,000 is `249`.

## TheAlgorithms references

- Project Euler [Problem 55](https://projecteuler.net/problem=55) treats a value as a Lychrel candidate if no palindrome appears in 50 reverse-and-add iterations.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_055/sol1.py) scans `range(1, limit)`, performs an addition before checking for a palindrome, and documents results of 13 below 1,000, 76 below 5,000, and 249 below 10,000.

The source therefore includes palindromic starting values that fail to reach a palindrome after the first addition; for example, it calls out 4,994. The workload preserves this 50-step check order.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem55.c](../../../c/p/problem55.c) |
| C3 | [c3/p/problem55.c3](../../../c3/p/problem55.c3) |
| C++ | [cpp/p/problem55.cpp](../../../cpp/p/problem55.cpp) |
| Elisa | [elisa/p/problem55.elisa](../../../elisa/p/problem55.elisa) |
| Nim | [nim/p/problem55.nim](../../../nim/p/problem55.nim) |
| Odin | [odin/p/problem55.odin](../../../odin/p/problem55.odin) |
| Rust | [rust/p/problem55.rs](../../../rust/p/problem55.rs) |
| V | [v/p/problem55.v](../../../v/p/problem55.v) |
| Zig | [zig/p/problem55.zig](../../../zig/p/problem55.zig) |
