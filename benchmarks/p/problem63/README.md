# Project Euler Problem 63: Powerful digit counts

## Contract

`problem63(max_base, max_power)` counts positive integer powers `base^power` whose decimal digit count equals `power`, with both loops following the pinned source's exclusive Python ranges: `base` in `range(1, max_base)` and `power` in `range(1, max_power)`. Bounds above 10 and 22 are capped because bases at least 10 and powers at least 22 cannot contribute; smaller and negative bounds naturally produce empty ranges. The return value is a signed 64-bit count.

The ports multiply a small little-endian decimal digit buffer by each base and compare its exact length with the power. This avoids floating-point digit estimates and fixed-width overflow. The canonical source call `(10, 22)` returns 49.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_063/sol1.py) defines `solution(max_base=10, max_power=22)`, uses exclusive ranges starting at 1, and counts when `len(str(base**power)) == power`. It documents 49 for `(10, 22)` and zero for `(0, 0)`, `(1, 1)`, and `(-1, -1)`. Its bounds justify the exact finite work represented by this package.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem63.c](../../../c/p/problem63.c) |
| C3 | [c3/p/problem63.c3](../../../c3/p/problem63.c3) |
| C++ | [cpp/p/problem63.cpp](../../../cpp/p/problem63.cpp) |
| Elisa | [elisa/p/problem63.elisa](../../../elisa/p/problem63.elisa) |
| Nim | [nim/p/problem63.nim](../../../nim/p/problem63.nim) |
| Odin | [odin/p/problem63.odin](../../../odin/p/problem63.odin) |
| Rust | [rust/p/problem63.rs](../../../rust/p/problem63.rs) |
| V | [v/p/problem63.v](../../../v/p/problem63.v) |
| Zig | [zig/p/problem63.zig](../../../zig/p/problem63.zig) |
