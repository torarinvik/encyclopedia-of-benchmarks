# Project Euler Problem 187

## Contract

For an exclusive maximum from 0 through 100,000,000, count unordered pairs of primes `p <= q` whose product is strictly less than the maximum. Invalid bounds return `-1`.

The ports follow the pinned `solution()` sieve cutoff and two-pointer count: the candidate prime list contains primes strictly below `max_number // 2`. This reproduces its small-bound behavior, including a result of **1** for 7 because the source cutoff omits prime 3. The source example returns **10** for 30, and its default bound 100,000,000 returns **17427258**.

## Workload

[`workload.json`](workload.json) covers empty/small prime pools, strict-bound edges, the source example, intermediate values, the canonical default, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_187/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem187.c](../../../c/p/problem187.c) |
| C3 | [c3/p/problem187.c3](../../../c3/p/problem187.c3) |
| C++ | [cpp/p/problem187.cpp](../../../cpp/p/problem187.cpp) |
| Elisa | [elisa/p/problem187.elisa](../../../elisa/p/problem187.elisa) |
| Nim | [nim/p/problem187.nim](../../../nim/p/problem187.nim) |
| Odin | [odin/p/problem187.odin](../../../odin/p/problem187.odin) |
| Rust | [rust/p/problem187.rs](../../../rust/p/problem187.rs) |
| V | [v/p/problem187.v](../../../v/p/problem187.v) |
| Zig | [zig/p/problem187.zig](../../../zig/p/problem187.zig) |
