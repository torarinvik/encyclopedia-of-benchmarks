# Project Euler Problem 53

## Contract

The pinned no-argument solution counts values of `nCr` strictly greater than 1,000,000 for `1 <= n <= 100` and `1 <= r <= n`. It counts each `(n, r)` position, including symmetric values in the same row. The fixed result is 4075.

The Python helper computes a factorial ratio with `/`, so its intermediate result is a float. For this fixed domain, the closest coefficients around the threshold are 971,635 and 1,028,790, so integer comparisons preserve the source's strict boundary. The ports use the exact recurrence `C(n,r) = C(n,r-1) * (n-r+1) / r`, scan through the increasing half of each row, and count the matching symmetric range after the first coefficient above the threshold. This avoids large factorial intermediates.

The scalar ABI uses an ignored placeholder constrained to zero; a nonzero placeholder returns -1.

## Workload

The workload contains the fixed source computation and a nonzero-placeholder boundary case. It uses seven samples, two warmups, and 1,000 calls per sample.

## TheAlgorithms reference

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_053/sol1.py

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem53 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem53/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem53.c](../../../c/p/problem53.c) |
| C3 | [c3/p/problem53.c3](../../../c3/p/problem53.c3) |
| C++ | [cpp/p/problem53.cpp](../../../cpp/p/problem53.cpp) |
| Elisa | [elisa/p/problem53.elisa](../../../elisa/p/problem53.elisa) |
| Nim | [nim/p/problem53.nim](../../../nim/p/problem53.nim) |
| Odin | [odin/p/problem53.odin](../../../odin/p/problem53.odin) |
| Rust | [rust/p/problem53.rs](../../../rust/p/problem53.rs) |
| V | [v/p/problem53.v](../../../v/p/problem53.v) |
| Zig | [zig/p/problem53.zig](../../../zig/p/problem53.zig) |
