# Project Euler Problem 17: Number letter counts

## Contract

Return the total number of letters used to write every integer from 1 through `limit` in British English, ignoring spaces and hyphens. `limit` is in `0..=1000`; values outside the range return `-1`. Zero has an empty range and returns `0`.

The ports count the units and teens from a letter-count table, combine tens with units, add “hundred” for three-digit values, add “and” when a three-digit value has a nonzero remainder, and count 1000 as “one thousand”. The loop takes O(limit) time and constant space.

## Workload

[`workload.json`](workload.json) covers the empty range, small examples, the 1..99 and 1..100 boundaries, the statement's 342 example, the canonical 1..1000 total, and invalid limits.

## TheAlgorithms references

- Python [`solution`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_017/sol1.py) implements the number-letter count for 1 through `n` and returns 21124 for `n = 1000`.
- Dart [`calculateWithRange`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/project_euler/problem_17/sol17.dart) converts each number to British English words and counts the letters over an inclusive range; its default 1..1000 range returns 21124.
- Go [`Problem17`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_17/problem17.go) accepts already-written words and sums their lengths after splitting on spaces. It does not generate number names from a numeric limit, so it is recorded as a semantic mismatch rather than an equivalent implementation.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem17.c](../../../c/p/problem17.c) |
| C3 | [c3/p/problem17.c3](../../../c3/p/problem17.c3) |
| C++ | [cpp/p/problem17.cpp](../../../cpp/p/problem17.cpp) |
| Elisa | [elisa/p/problem17.elisa](../../../elisa/p/problem17.elisa) |
| Nim | [nim/p/problem17.nim](../../../nim/p/problem17.nim) |
| Odin | [odin/p/problem17.odin](../../../odin/p/problem17.odin) |
| Rust | [rust/p/problem17.rs](../../../rust/p/problem17.rs) |
| V | [v/p/problem17.v](../../../v/p/problem17.v) |
| Zig | [zig/p/problem17.zig](../../../zig/p/problem17.zig) |
