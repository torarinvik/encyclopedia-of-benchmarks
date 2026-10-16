# Project Euler Problem 22: Names Scores

## Contract

The input is a packed signed 64-bit integer array: the first value is the number of names, followed by each name's length and its letters encoded as `A = 1` through `Z = 26`. The function sorts the names lexicographically, gives each letter its alphabet value, multiplies each name value by its 1-based sorted position, and returns the sum. An empty list returns `0`. Invalid lengths, counts, or letter codes return `-1`.

The bounds are at most 6,000 names, 1–19 letters per name, and 100,001 packed values. The packed representation keeps the classic file-backed exercise self-contained: no language port reads a names file at runtime.

## Workload

[`workload.json`](workload.json) covers an empty list, a single name, unsorted input, duplicate names, prefix ordering, malformed encodings, and the complete official 5,163-name dataset. The canonical dataset case returns `871,198,282`.

## TheAlgorithms references

- Project Euler [Problem 22](https://projecteuler.net/problem=22) defines the alphabetical name-score calculation and links the names dataset used by the canonical workload.
- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_022/sol1.py) and [`sol2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_022/sol2.py), and Ruby [`sol1.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/project_euler/problem_022/sol1.rb), read the external names file, sort its names, and sum the same rank-weighted letter values.
- C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_22/sol1.c) implements shell and lazy sorting before scoring a fixed `names.txt` file. Its input loop increments `COUNT` as part of the `fscanf` argument before checking whether a name was read, and the program is a file-backed CLI with timing output rather than a callable function over the benchmark's packed input. The port preserves the intended sort-and-score algorithm and validates the input explicitly.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem22.c](../../../c/p/problem22.c) |
| C3 | [c3/p/problem22.c3](../../../c3/p/problem22.c3) |
| C++ | [cpp/p/problem22.cpp](../../../cpp/p/problem22.cpp) |
| Elisa | [elisa/p/problem22.elisa](../../../elisa/p/problem22.elisa) |
| Nim | [nim/p/problem22.nim](../../../nim/p/problem22.nim) |
| Odin | [odin/p/problem22.odin](../../../odin/p/problem22.odin) |
| Rust | [rust/p/problem22.rs](../../../rust/p/problem22.rs) |
| V | [v/p/problem22.v](../../../v/p/problem22.v) |
| Zig | [zig/p/problem22.zig](../../../zig/p/problem22.zig) |
