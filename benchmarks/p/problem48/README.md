# Project Euler Problem 48

## Contract

The pinned no-argument solution sums `i^i` for `i` from 1 through 1000 and returns the last ten decimal digits as a string. Its result is `'9110846700'`. The scalar workload represents this fixed ten-digit suffix as the integer 9110846700; this result has no leading zeroes.

The scalar ABI uses an ignored placeholder constrained to zero; a nonzero placeholder returns -1. Each port reduces the running term and total modulo 10^10 so the intermediates fit signed 64-bit arithmetic. The package keeps the source's fixed bound instead of adding a variable upper bound, which would require modeling zero-padded string suffixes.

## Workload

The workload contains the fixed source computation and a nonzero-placeholder boundary case. It uses three samples, one warmup, and one call per sample.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_048/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem48 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem48/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem48.c](../../../c/p/problem48.c) |
| C3 | [c3/p/problem48.c3](../../../c3/p/problem48.c3) |
| C++ | [cpp/p/problem48.cpp](../../../cpp/p/problem48.cpp) |
| Elisa | [elisa/p/problem48.elisa](../../../elisa/p/problem48.elisa) |
| Nim | [nim/p/problem48.nim](../../../nim/p/problem48.nim) |
| Odin | [odin/p/problem48.odin](../../../odin/p/problem48.odin) |
| Rust | [rust/p/problem48.rs](../../../rust/p/problem48.rs) |
| V | [v/p/problem48.v](../../../v/p/problem48.v) |
| Zig | [zig/p/problem48.zig](../../../zig/p/problem48.zig) |
