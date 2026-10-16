# Project Euler Problem 114: Counting Block Combinations I

## Contract

For a row length from 0 through 50, count the ways to fill it with grey squares and red blocks of length at least three. Any two red blocks must have at least one grey square between them. A row containing only grey squares is one arrangement. Invalid lengths return -1.

The ports preserve the pinned source's recurrence. For each row length `r` from 3 to the requested length and each red block length `b` from 3 to `r`, they add the previously counted ways for every block start before the right edge, then add one arrangement with the block reaching the right edge. This permits mixing red block sizes and counts all-grey rows through the initial value of one.

The source example is `length=7 → 17`. Its default length of 50 returns **16475640049**.

## Workload

[`workload.json`](workload.json) covers lengths 0 through 8 around the minimum red-block size, the source example, the canonical default, and invalid bounds.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_114/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem114 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem114/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem114.c](../../../c/p/problem114.c) |
| C3 | [c3/p/problem114.c3](../../../c3/p/problem114.c3) |
| C++ | [cpp/p/problem114.cpp](../../../cpp/p/problem114.cpp) |
| Elisa | [elisa/p/problem114.elisa](../../../elisa/p/problem114.elisa) |
| Nim | [nim/p/problem114.nim](../../../nim/p/problem114.nim) |
| Odin | [odin/p/problem114.odin](../../../odin/p/problem114.odin) |
| Rust | [rust/p/problem114.rs](../../../rust/p/problem114.rs) |
| V | [v/p/problem114.v](../../../v/p/problem114.v) |
| Zig | [zig/p/problem114.zig](../../../zig/p/problem114.zig) |
