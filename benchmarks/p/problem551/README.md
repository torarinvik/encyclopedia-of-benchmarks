# Project Euler Problem 551: sum of digits sequence

## Contract

`problem551(n)` returns term `a(n)` from `a(0)=1` and `a(k)=a(k-1)+digit_sum(a(k-1))`. The benchmark supports `1 <= n <= 1,000,000,000,000,000`; values outside this range return `-1`. The ports preserve the pinned decimal-prefix jump cache, with a fixed upper digit block that fits the bounded result in signed 64-bit arithmetic.

The pinned examples are `a(10)=62`, `a(1,000,000)=31,054,319`, and `a(1,000,000,000,000,000)=73,597,483,551,591,773`.

## Cache capacity bound

The supported maximum index is `10^15`. The recurrence is deterministic, and a run for a smaller index follows a prefix of the maximum-index traversal; cached jumps are built only after recursively visiting the block they cover. The maximum-index integer model visits 6,310 distinct `(prefix digit sum, suffix)` states, below the 32,768-slot state table. The ports store only completed block-rollover jumps, not terminal partial jumps. Each state can therefore store at most one jump for each block size `k=2..18`, giving an upper bound of `6,310 × 17 = 107,270` jump entries, below the 131,072-entry jump table.

## Workload

[`workload.json`](workload.json) covers the first terms, both documented examples, the default target, and out-of-range indices.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_551/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem551.c](../../../c/p/problem551.c) |
| C3 | [c3/p/problem551.c3](../../../c3/p/problem551.c3) |
| C++ | [cpp/p/problem551.cpp](../../../cpp/p/problem551.cpp) |
| Elisa | [elisa/p/problem551.elisa](../../../elisa/p/problem551.elisa) |
| Nim | [nim/p/problem551.nim](../../../nim/p/problem551.nim) |
| Odin | [odin/p/problem551.odin](../../../odin/p/problem551.odin) |
| Rust | [rust/p/problem551.rs](../../../rust/p/problem551.rs) |
| V | [v/p/problem551.v](../../../v/p/problem551.v) |
| Zig | [zig/p/problem551.zig](../../../zig/p/problem551.zig) |
