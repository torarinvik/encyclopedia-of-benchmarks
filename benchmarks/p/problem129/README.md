# Project Euler Problem 129: Repunit divisibility

## Contract

The pinned helper returns 0 when the divisor is even or divisible by 5. Otherwise it starts with remainder 1 and index 1, repeatedly updates `remainder = (10 × remainder + 1) % divisor`, and increments the index until the remainder becomes zero. The solution starts at `limit - 1`, increases that candidate once if it is even, and advances by 2 while the helper result is at most the limit. It returns the first candidate whose helper result strictly exceeds the limit.

The benchmark supports limits 1 through 1,000,000; values outside the range return -1. The source examples return 17 for 10, 109 for 100, and 1,017 for 1,000. The source default limit of 1,000,000 returns 1,000,023.

The ports preserve the source's remainder recurrence, even/five-divisibility shortcut, initial candidate adjustment, odd-only candidate order, and `<=` continuation rule.

## Workload

The [workload JSON](workload.json) covers small limits, initial candidates divisible by 5, source examples and default, and out-of-domain values.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_129/sol1.py) searches for the first candidate whose repunit length exceeds the limit.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem129.c](../../../c/p/problem129.c) |
| C3 | [c3/p/problem129.c3](../../../c3/p/problem129.c3) |
| C++ | [cpp/p/problem129.cpp](../../../cpp/p/problem129.cpp) |
| Elisa | [elisa/p/problem129.elisa](../../../elisa/p/problem129.elisa) |
| Nim | [nim/p/problem129.nim](../../../nim/p/problem129.nim) |
| Odin | [odin/p/problem129.odin](../../../odin/p/problem129.odin) |
| Rust | [rust/p/problem129.rs](../../../rust/p/problem129.rs) |
| V | [v/p/problem129.v](../../../v/p/problem129.v) |
| Zig | [zig/p/problem129.zig](../../../zig/p/problem129.zig) |
