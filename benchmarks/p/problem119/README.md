# Project Euler Problem 119: Digit power sum

## Contract

`problem119(index)` returns the one-based `index`th sorted value that equals a power of its own digit sum. The workload supports indices 1 through 30; other inputs return `-1`. The canonical 30th value is 248,155,780,267,521.

The search preserves the source’s candidate enumeration: bases 2 through 99 and powers 2 through 99, both with exclusive upper bounds. A candidate is appended when its decimal digit sum equals its base. The complete candidate multiset is sorted, and the requested entry is returned. Values retain duplicates if separate enumerations produce the same value. The benchmark bounds the index to 30 and keeps candidates within signed 64-bit range; the first 30 source values match this exact integer enumeration.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_119/sol1.py) uses `int(math.pow(base, exponent))` for each base and exponent in `range(2, 100)`, filters values whose digit sum equals the base, sorts all matches, and returns position `index - 1`. The benchmark preserves the candidate bounds, filter, sort order, and one-based indexing. Exact checked integer multiplication avoids floating-point conversion and signed overflow; the supported range includes the source examples and requested 30th term.

## Workload

[`workload.json`](workload.json) includes the first value, source examples at indices 2, 5, and 10, canonical index 30, and invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem119.c](../../../c/p/problem119.c) |
| C3 | [c3/p/problem119.c3](../../../c3/p/problem119.c3) |
| C++ | [cpp/p/problem119.cpp](../../../cpp/p/problem119.cpp) |
| Elisa | [elisa/p/problem119.elisa](../../../elisa/p/problem119.elisa) |
| Nim | [nim/p/problem119.nim](../../../nim/p/problem119.nim) |
| Odin | [odin/p/problem119.odin](../../../odin/p/problem119.odin) |
| Rust | [rust/p/problem119.rs](../../../rust/p/problem119.rs) |
| V | [v/p/problem119.v](../../../v/p/problem119.v) |
| Zig | [zig/p/problem119.zig](../../../zig/p/problem119.zig) |
