# Project Euler Problem 345

## Contract

Input is a signed-64-bit array containing `[n, row-major matrix values...]`. For a square `n × n` matrix with `1 <= n <= 15` and entries in `0..1000`, return the greatest sum obtainable by selecting exactly one value from each row and column. The packed input length must be exactly `n*n + 1`; invalid input returns `-1`.

The source parses square matrices and recursively assigns one unused column to each row, caching by row and remaining columns. The ports use an equivalent subset dynamic program. The source's 2×2 example returns **5**, its 5×5 `MATRIX_1` returns **3315**, and the default 15×15 `MATRIX_2` returns **13938**.

## Workload

[`workload.json`](workload.json) carries the 2×2 example, both pinned matrices, a 1×1 case, and malformed dimensions, lengths, and values.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_345/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem345.c](../../../c/p/problem345.c) |
| C3 | [c3/p/problem345.c3](../../../c3/p/problem345.c3) |
| C++ | [cpp/p/problem345.cpp](../../../cpp/p/problem345.cpp) |
| Elisa | [elisa/p/problem345.elisa](../../../elisa/p/problem345.elisa) |
| Nim | [nim/p/problem345.nim](../../../nim/p/problem345.nim) |
| Odin | [odin/p/problem345.odin](../../../odin/p/problem345.odin) |
| Rust | [rust/p/problem345.rs](../../../rust/p/problem345.rs) |
| V | [v/p/problem345.v](../../../v/p/problem345.v) |
| Zig | [zig/p/problem345.zig](../../../zig/p/problem345.zig) |
