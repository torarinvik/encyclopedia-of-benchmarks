# Project Euler Problem 30

## Contract

The source operation takes no arguments and scans integers from 1,000 through 999,999, inclusive, returning the sum of those equal to the sum of their decimal digits raised to the fifth power. The fixed dataset result is 443,839.

The scalar ABI uses an ignored placeholder constrained to zero. A nonzero placeholder returns -1. The source loop uses an exclusive upper bound of 1,000,000, so seven-digit values are not scanned.

## Workload

The workload contains the fixed source computation and a nonzero-placeholder boundary case. It uses one repetition per sample because the source scans nearly one million candidates.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_030/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem30 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem30/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem30.c](../../../c/p/problem30.c) |
| C3 | [c3/p/problem30.c3](../../../c3/p/problem30.c3) |
| C++ | [cpp/p/problem30.cpp](../../../cpp/p/problem30.cpp) |
| Elisa | [elisa/p/problem30.elisa](../../../elisa/p/problem30.elisa) |
| Nim | [nim/p/problem30.nim](../../../nim/p/problem30.nim) |
| Odin | [odin/p/problem30.odin](../../../odin/p/problem30.odin) |
| Rust | [rust/p/problem30.rs](../../../rust/p/problem30.rs) |
| V | [v/p/problem30.v](../../../v/p/problem30.v) |
| Zig | [zig/p/problem30.zig](../../../zig/p/problem30.zig) |
