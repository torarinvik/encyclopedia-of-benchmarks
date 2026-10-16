# Project Euler Problem 40

## Contract

The pinned no-argument solution returns the product of the Champernowne constant's decimal digits at 1-indexed positions 1, 10, 100, 1,000, 10,000, 100,000, and 1,000,000. Its result is 210.

The scalar ABI uses an ignored placeholder constrained to zero; a nonzero placeholder returns -1. The pinned Python implementation appends one million integer strings because its loop checks the list length, then reads only the first million concatenated decimal digits. The ports locate the selected digits by decimal digit-width blocks and preserve the same positions without materializing that prefix.

## Workload

The workload contains the fixed source computation and a nonzero-placeholder boundary case. It uses three samples, one warmup, and one call per sample.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_040/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem40 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem40/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem40.c](../../../c/p/problem40.c) |
| C3 | [c3/p/problem40.c3](../../../c3/p/problem40.c3) |
| C++ | [cpp/p/problem40.cpp](../../../cpp/p/problem40.cpp) |
| Elisa | [elisa/p/problem40.elisa](../../../elisa/p/problem40.elisa) |
| Nim | [nim/p/problem40.nim](../../../nim/p/problem40.nim) |
| Odin | [odin/p/problem40.odin](../../../odin/p/problem40.odin) |
| Rust | [rust/p/problem40.rs](../../../rust/p/problem40.rs) |
| V | [v/p/problem40.v](../../../v/p/problem40.v) |
| Zig | [zig/p/problem40.zig](../../../zig/p/problem40.zig) |
