# Project Euler Problem 137

## Contract

For a nugget index from 1 through 23, return the indexed Fibonacci golden nugget `F(2n) × F(2n + 1)`, using `F(1) = F(2) = 1`. Invalid indices return `-1`. The bound keeps the result within signed 64-bit range.

The ports preserve the pinned source's iterative Fibonacci calculation. Its examples return **104** for index 3 and **74049690** for index 10. The source default, index 15, returns **1120149658760**; index 23 is the largest supported result.

## Workload

[`workload.json`](workload.json) includes the first values, source examples and default, the largest supported index, and invalid values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_137/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem137.c](../../../c/p/problem137.c) |
| C3 | [c3/p/problem137.c3](../../../c3/p/problem137.c3) |
| C++ | [cpp/p/problem137.cpp](../../../cpp/p/problem137.cpp) |
| Elisa | [elisa/p/problem137.elisa](../../../elisa/p/problem137.elisa) |
| Nim | [nim/p/problem137.nim](../../../nim/p/problem137.nim) |
| Odin | [odin/p/problem137.odin](../../../odin/p/problem137.odin) |
| Rust | [rust/p/problem137.rs](../../../rust/p/problem137.rs) |
| V | [v/p/problem137.v](../../../v/p/problem137.v) |
| Zig | [zig/p/problem137.zig](../../../zig/p/problem137.zig) |
