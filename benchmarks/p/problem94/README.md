# Project Euler Problem 94

## Contract

For an inclusive perimeter limit from 0 through 1,000,000,000, return the sum of the perimeters of all integer-sided almost-equilateral triangles with integral area whose perimeters do not exceed the limit. Invalid limits return `-1`.

Each port preserves the pinned source's Pell-style enumeration and update order. It starts with `previous = 1`, `value = 2`, and perimeter zero; each iteration adds the current perimeter, updates `previous += 2 * value` and then `value += previous`, and chooses the next perimeter as `2 * value + 2` on even iterations or `2 * value - 2` on odd iterations. The input bound keeps all intermediate values in signed 64-bit range.

The source example returns **16** for limit 20. At the canonical limit 1,000,000,000, the sum is **518408346**.

## Workload

[`workload.json`](workload.json) covers the zero result, the source example, both first-perimeter boundaries, the canonical limit, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_094/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem94.c](../../../c/p/problem94.c) |
| C3 | [c3/p/problem94.c3](../../../c3/p/problem94.c3) |
| C++ | [cpp/p/problem94.cpp](../../../cpp/p/problem94.cpp) |
| Elisa | [elisa/p/problem94.elisa](../../../elisa/p/problem94.elisa) |
| Nim | [nim/p/problem94.nim](../../../nim/p/problem94.nim) |
| Odin | [odin/p/problem94.odin](../../../odin/p/problem94.odin) |
| Rust | [rust/p/problem94.rs](../../../rust/p/problem94.rs) |
| V | [v/p/problem94.v](../../../v/p/problem94.v) |
| Zig | [zig/p/problem94.zig](../../../zig/p/problem94.zig) |
