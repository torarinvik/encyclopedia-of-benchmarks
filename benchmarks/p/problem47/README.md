# Project Euler Problem 47

## Contract

The pinned `solution(n=4)` returns the first value in the first run of `n` consecutive integers that each have `n` distinct prime factors. The benchmark accepts `n` from 1 through 4; the canonical default result is 134043. The pinned source documents the run starts 14 for `n=2` and 644 for `n=3`.

Inputs outside 1..4 return -1. This bounded domain keeps the scalar workload finite and includes the pinned default. The Python source trial-divides each value, caches distinct-factor counts with `lru_cache`, and checks overlapping windows. The ports count distinct prime factors by trial division and track the current run as values increase.

## Workload

The workload covers all supported run lengths, the pinned default, and both invalid range boundaries. It uses three samples, one warmup, and one call per sample because the canonical search is substantially longer than a constant-time scalar operation.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_047/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem47 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem47/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem47.c](../../../c/p/problem47.c) |
| C3 | [c3/p/problem47.c3](../../../c3/p/problem47.c3) |
| C++ | [cpp/p/problem47.cpp](../../../cpp/p/problem47.cpp) |
| Elisa | [elisa/p/problem47.elisa](../../../elisa/p/problem47.elisa) |
| Nim | [nim/p/problem47.nim](../../../nim/p/problem47.nim) |
| Odin | [odin/p/problem47.odin](../../../odin/p/problem47.odin) |
| Rust | [rust/p/problem47.rs](../../../rust/p/problem47.rs) |
| V | [v/p/problem47.v](../../../v/p/problem47.v) |
| Zig | [zig/p/problem47.zig](../../../zig/p/problem47.zig) |
