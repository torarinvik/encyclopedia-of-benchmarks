# Project Euler Problem 64

## Contract

For an inclusive limit `n` from 0 through 10,000, return the count of non-square integers in `2..=n` whose square-root continued fraction has an odd period. Limits below 2 return 0; out-of-range values return `-1`.

The ports use the standard exact integer recurrence for the continued-fraction coefficients. It matches the pinned source's period loop, which updates the numerator, denominator, and integer coefficient until that coefficient reaches `2 * floor(sqrt(n))`. The source examples are `2 -> 1`, `5 -> 2`, `7 -> 2`, `11 -> 3`, and `13 -> 4`; the default bound 10,000 returns 1,322.

Each language exports `int64_t problem64(int64_t inclusive_limit)`.

## Workload

[`workload.json`](workload.json) covers lower bounds, the source's documented examples, the canonical limit, and invalid limits.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_064/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem64.c](../../../c/p/problem64.c) |
| C3 | [c3/p/problem64.c3](../../../c3/p/problem64.c3) |
| C++ | [cpp/p/problem64.cpp](../../../cpp/p/problem64.cpp) |
| Elisa | [elisa/p/problem64.elisa](../../../elisa/p/problem64.elisa) |
| Nim | [nim/p/problem64.nim](../../../nim/p/problem64.nim) |
| Odin | [odin/p/problem64.odin](../../../odin/p/problem64.odin) |
| Rust | [rust/p/problem64.rs](../../../rust/p/problem64.rs) |
| V | [v/p/problem64.v](../../../v/p/problem64.v) |
| Zig | [zig/p/problem64.zig](../../../zig/p/problem64.zig) |
