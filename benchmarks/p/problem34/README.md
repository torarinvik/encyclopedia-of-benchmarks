# Project Euler Problem 34: Digit factorials

## Contract

The pinned Python `solution()` takes no arguments. It scans each integer from 3 through `7 * 9!` inclusive, and adds values equal to the sum of the factorials of their decimal digits. The scalar ABI uses zero as an ignored placeholder; nonzero inputs return `-1`. The fixed result is `40,730`, from `145` and `40,585`.

The scan bound is source-derived: `limit = 7 * factorial(9) + 1`, used as the exclusive upper bound of Python's `range(3, limit)`. Seven digits are the longest possible because an eight-digit value exceeds the largest possible digit-factorial sum. The source deliberately starts at 3, so 1 and 2 are excluded.

## Workload

[`workload.json`](workload.json) covers the fixed source computation and both positive and negative invalid placeholders. The fixed scan uses one repetition per sample.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_034/sol1.py) precomputes the decimal digit factorials and scans the same fixed range.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem34.c](../../../c/p/problem34.c) |
| C3 | [c3/p/problem34.c3](../../../c3/p/problem34.c3) |
| C++ | [cpp/p/problem34.cpp](../../../cpp/p/problem34.cpp) |
| Elisa | [elisa/p/problem34.elisa](../../../elisa/p/problem34.elisa) |
| Nim | [nim/p/problem34.nim](../../../nim/p/problem34.nim) |
| Odin | [odin/p/problem34.odin](../../../odin/p/problem34.odin) |
| Rust | [rust/p/problem34.rs](../../../rust/p/problem34.rs) |
| V | [v/p/problem34.v](../../../v/p/problem34.v) |
| Zig | [zig/p/problem34.zig](../../../zig/p/problem34.zig) |
