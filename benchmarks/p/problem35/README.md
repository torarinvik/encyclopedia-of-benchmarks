# Project Euler Problem 35

## Contract

The pinned no-argument solution returns the number of circular primes found by its default search through 1,000,000, inclusive. A circular prime remains prime under every rotation of its decimal digits. The result for the pinned source is 55.

The scalar ABI uses an ignored placeholder constrained to zero; a nonzero placeholder returns -1. The source pre-adds 2, scans odd candidates from 3 through its inclusive limit, skips numbers containing an even digit, and checks every digit rotation against its prime sieve.

The ports build a compact odd-only sieve during the call. The pinned Python module instead creates a full sieve at import time; this benchmark measures the complete fixed operation in each compiled port.

## Workload

The workload contains the source's fixed search and a nonzero-placeholder boundary case. It uses one repetition per sample because each call builds a sieve through one million.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_035/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem35 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem35/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem35.c](../../../c/p/problem35.c) |
| C3 | [c3/p/problem35.c3](../../../c3/p/problem35.c3) |
| C++ | [cpp/p/problem35.cpp](../../../cpp/p/problem35.cpp) |
| Elisa | [elisa/p/problem35.elisa](../../../elisa/p/problem35.elisa) |
| Nim | [nim/p/problem35.nim](../../../nim/p/problem35.nim) |
| Odin | [odin/p/problem35.odin](../../../odin/p/problem35.odin) |
| Rust | [rust/p/problem35.rs](../../../rust/p/problem35.rs) |
| V | [v/p/problem35.v](../../../v/p/problem35.v) |
| Zig | [zig/p/problem35.zig](../../../zig/p/problem35.zig) |
