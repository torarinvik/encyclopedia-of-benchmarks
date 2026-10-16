# Project Euler Problem 125: Palindromic Sums

## Contract

For an exclusive limit from 0 through 100,000,000, return the sum of the distinct palindromic values below that limit that can be written as the sum of at least two consecutive squares of positive integers. Invalid limits return -1. The strict bound excludes a sum equal to the limit, and duplicate representations contribute only once.

The scan starts each sequence at `first² + (first + 1)²` and extends its final square until the sum reaches the limit. The pinned source uses a set for distinct values; the ports use open addressing with 32,768 slots. There are at most 19,998 positive decimal palindromes below 100,000,000, so that table can hold every value in the supported domain.

The problem statement's sub-1,000 example returns **4164**; the canonical 100,000,000 limit returns **2906969179**.

## Workload

[`workload.json`](workload.json) covers empty and strict-bound behavior, the source example, the canonical limit, and invalid limits. The canonical scan uses one sample, no warmup, and one measured call because it enumerates millions of consecutive-square sums.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_125/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem125 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem125/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem125.c](../../../c/p/problem125.c) |
| C3 | [c3/p/problem125.c3](../../../c3/p/problem125.c3) |
| C++ | [cpp/p/problem125.cpp](../../../cpp/p/problem125.cpp) |
| Elisa | [elisa/p/problem125.elisa](../../../elisa/p/problem125.elisa) |
| Nim | [nim/p/problem125.nim](../../../nim/p/problem125.nim) |
| Odin | [odin/p/problem125.odin](../../../odin/p/problem125.odin) |
| Rust | [rust/p/problem125.rs](../../../rust/p/problem125.rs) |
| V | [v/p/problem125.v](../../../v/p/problem125.v) |
| Zig | [zig/p/problem125.zig](../../../zig/p/problem125.zig) |
