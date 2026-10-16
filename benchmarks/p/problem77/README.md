# Project Euler Problem 77

## Contract

The pinned Python source generates the primes below 100, recursively enumerates unique prime partitions, and returns the first value from 1 through 99 whose partition count is strictly greater than the requested threshold. The benchmark accepts thresholds from 0 through 100,000; negative and out-of-range thresholds return `-1`. The source returns `None` when no value below 100 crosses the threshold; the scalar adapter maps that no-result case to `-1`.

Ports use the equivalent unbounded-coin recurrence over primes: initialize `ways[0] = 1`, then for each prime add `ways[total - prime]` for increasing totals. The default threshold 5,000 returns `71`.

Each language exports `int64_t problem77(int64_t threshold)`.

## Workload

[`workload.json`](workload.json) includes the source examples, default answer, last reachable threshold, no-result thresholds, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_077/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem77.c](../../../c/p/problem77.c) |
| C3 | [c3/p/problem77.c3](../../../c3/p/problem77.c3) |
| C++ | [cpp/p/problem77.cpp](../../../cpp/p/problem77.cpp) |
| Elisa | [elisa/p/problem77.elisa](../../../elisa/p/problem77.elisa) |
| Nim | [nim/p/problem77.nim](../../../nim/p/problem77.nim) |
| Odin | [odin/p/problem77.odin](../../../odin/p/problem77.odin) |
| Rust | [rust/p/problem77.rs](../../../rust/p/problem77.rs) |
| V | [v/p/problem77.v](../../../v/p/problem77.v) |
| Zig | [zig/p/problem77.zig](../../../zig/p/problem77.zig) |
