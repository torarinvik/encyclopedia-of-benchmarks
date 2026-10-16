# Project Euler Problem 65: Convergents of e

## Contract

The pinned `solution(max_n=100)` returns the digit sum of the numerator of the `max_n`-th convergent of e's continued fraction. The benchmark supports indices 1 through 100, including the pinned default and documented source examples. Results include `n=9 → 13`, `n=10 → 17`, `n=50 → 91`, and the canonical `n=100 → 272`. Inputs outside the supported range return -1.

The numerator starts with `1, 2`. For each index `i` from 2 through `max_n`, the source coefficient is `2*i//3` when `i` is divisible by 3, and 1 otherwise; the recurrence is `current = coefficient*current + previous`. The ports keep decimal digits in fixed local arrays, applying the recurrence exactly without fixed-width integer overflow, then sum those digits.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_065/sol1.py

## Workload

The workload covers the first convergent, all documented examples, the canonical default, and both input bounds. It uses three samples, one warmup, and 1,000 calls per sample.

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem65 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem65/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem65.c](../../../c/p/problem65.c) |
| C3 | [c3/p/problem65.c3](../../../c3/p/problem65.c3) |
| C++ | [cpp/p/problem65.cpp](../../../cpp/p/problem65.cpp) |
| Elisa | [elisa/p/problem65.elisa](../../../elisa/p/problem65.elisa) |
| Nim | [nim/p/problem65.nim](../../../nim/p/problem65.nim) |
| Odin | [odin/p/problem65.odin](../../../odin/p/problem65.odin) |
| Rust | [rust/p/problem65.rs](../../../rust/p/problem65.rs) |
| V | [v/p/problem65.v](../../../v/p/problem65.v) |
| Zig | [zig/p/problem65.zig](../../../zig/p/problem65.zig) |
