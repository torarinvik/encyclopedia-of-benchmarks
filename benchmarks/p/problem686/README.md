# Project Euler Problem 686: powers of two with a leading prefix

## Contract

For an occurrence index from 1 through 678,910, return the exponent `j` of the requested power `2^j` whose decimal representation begins with `123`. Values outside the benchmark domain return `-1`.

The pinned source starts at exponent 90 and tracks the fractional part of `j × log10(2)`. It advances by 93 when the fraction is at or above `log10(1.24)`, by 196 when it is below `log10(1.23)`, and otherwise records a match, advances by 196, and increments the occurrence count. The ports preserve that interval scan, its initial exponent, and its return of the last recorded match. Binary64 constants preserve the source logarithms; the 15-place rounding is ties-to-even.

The source examples return **90** for occurrence 1, **2,515** for occurrence 10, **12,710** for occurrence 45, **284,168** for occurrence 1,000, and **15,924,915** for occurrence 56,000. The canonical occurrence 678,910 returns **193,060,223**.

## Workload

[`workload.json`](workload.json) covers source examples, the canonical occurrence, and invalid values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_686/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem686.c](../../../c/p/problem686.c) |
| C3 | [c3/p/problem686.c3](../../../c3/p/problem686.c3) |
| C++ | [cpp/p/problem686.cpp](../../../cpp/p/problem686.cpp) |
| Elisa | [elisa/p/problem686.elisa](../../../elisa/p/problem686.elisa) |
| Nim | [nim/p/problem686.nim](../../../nim/p/problem686.nim) |
| Odin | [odin/p/problem686.odin](../../../odin/p/problem686.odin) |
| Rust | [rust/p/problem686.rs](../../../rust/p/problem686.rs) |
| V | [v/p/problem686.v](../../../v/p/problem686.v) |
| Zig | [zig/p/problem686.zig](../../../zig/p/problem686.zig) |
