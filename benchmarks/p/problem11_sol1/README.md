# Project Euler Problem 11, Python sol1

## Contract

The pinned no-argument `solution()` loads the fixed 20×20 grid from `grid.txt` and returns the greatest product of four adjacent entries horizontally, vertically, or diagonally. The scalar benchmark uses an ignored placeholder that must be zero; other values return `-1`. The pinned result is `70,600,674`.

The ports inline the pinned grid and scan the same four directions. The source's `largest_product` helper assumes a square grid; this benchmark preserves the fixed square input and does not expose arbitrary matrices.

## Workload

[`workload.json`](workload.json) covers the pinned result and invalid scalar placeholders.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_011/sol1.py)
- Python [`sol2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_011/sol2.py) has the same fixed 20×20 grid and checks the same four directions in separate loops. It is mapped to this benchmark as an alias; the Go/PHP `problem11` candidate remains separate.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem11_sol1.c](../../../c/p/problem11_sol1.c) |
| C3 | [c3/p/problem11_sol1.c3](../../../c3/p/problem11_sol1.c3) |
| C++ | [cpp/p/problem11_sol1.cpp](../../../cpp/p/problem11_sol1.cpp) |
| Elisa | [elisa/p/problem11_sol1.elisa](../../../elisa/p/problem11_sol1.elisa) |
| Nim | [nim/p/problem11_sol1.nim](../../../nim/p/problem11_sol1.nim) |
| Odin | [odin/p/problem11_sol1.odin](../../../odin/p/problem11_sol1.odin) |
| Rust | [rust/p/problem11_sol1.rs](../../../rust/p/problem11_sol1.rs) |
| V | [v/p/problem11_sol1.v](../../../v/p/problem11_sol1.v) |
| Zig | [zig/p/problem11_sol1.zig](../../../zig/p/problem11_sol1.zig) |
