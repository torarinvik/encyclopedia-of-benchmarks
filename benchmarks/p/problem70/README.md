# Project Euler Problem 70: Totient Permutation

## Contract

For an inclusive limit from 0 through 10,000,000, return the integer `n` in `2..=max_n` for which `n` and `φ(n)` contain the same decimal digits and `n / φ(n)` is smallest. The source scans in ascending order and uses a strict ratio comparison, so an equal ratio keeps the earlier value. If the range contains no qualifying candidate, the source's initial answer `1` is returned. Inputs outside the supported range return `-1`.

The ports use a segmented totient sieve. Each segment starts with `φ(k)=k`; prime factors update each multiple, and any remaining factor is applied at the end. Candidates are then checked in ascending order using exact 64-bit cross-products and decimal digit counts. This keeps the working arrays bounded while preserving the source's search and tie behavior.

The pinned Python source defaults to 10,000,000. Its documented examples include `max_n=100 → 21` and `max_n=10,000 → 4435`; the canonical result at 10,000,000 is **8319823**.

## Workload

[`workload.json`](workload.json) covers empty and low ranges, the documented examples, the canonical full bound, and invalid limits. The full-bound case performs the complete search, so measurement uses one sample, no warmup, and one call per sample.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_070/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem70 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem70/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem70.c](../../../c/p/problem70.c) |
| C3 | [c3/p/problem70.c3](../../../c3/p/problem70.c3) |
| C++ | [cpp/p/problem70.cpp](../../../cpp/p/problem70.cpp) |
| Elisa | [elisa/p/problem70.elisa](../../../elisa/p/problem70.elisa) |
| Nim | [nim/p/problem70.nim](../../../nim/p/problem70.nim) |
| Odin | [odin/p/problem70.odin](../../../odin/p/problem70.odin) |
| Rust | [rust/p/problem70.rs](../../../rust/p/problem70.rs) |
| V | [v/p/problem70.v](../../../v/p/problem70.v) |
| Zig | [zig/p/problem70.zig](../../../zig/p/problem70.zig) |
