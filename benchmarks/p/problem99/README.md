# Project Euler Problem 99: Largest Exponential

## Contract

Given a list of positive base/exponent pairs, return the one-based line number whose value is largest. The `i64_array_scalar` input is `[pair_count, base_0, exponent_0, ...]`. Pair count must be 0 through 1,000, each base 1 through 1,000,000, and each exponent 0 through 1,200,000. The packed length must be exactly `1 + 2*pair_count`. Invalid inputs return -1.

The source compares `exponent * log10(base)` using floating point and updates only for a strict increase. The ports preserve this comparison and its earliest-line tie behavior. The empty input list returns the source's initial line result, 0.

The first two pairs in the pinned dataset are the problem's example: `632382^518061` is greater than `519432^525806`. The pinned 1,000-pair file's greatest value is on line **709**.

## Pinned dataset

[`base_exp.txt`](base_exp.txt) is copied verbatim from TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, path `project_euler/problem_099/base_exp.txt`. It contains 1,000 comma-separated base/exponent pairs and has SHA-256 `e01d71a98368238a97ec057a824dd926295ddf15029d757621aa1c09258fb199`. The workload embeds the flattened values; compiled ports do not read files or access the network.

See [`DATASET_PROVENANCE.md`](DATASET_PROVENANCE.md) for the pinned source and dataset record.

## Workload

[`workload.json`](workload.json) covers singleton and example comparisons, repeated equal values, the pinned dataset, empty input, and malformed pairs. Each call compares at most 1,000 pairs.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_099/sol1.py)
- Python [`base_exp.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_099/base_exp.txt)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm problem99 --language rust

Run it with:

    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/problem99/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem99.c](../../../c/p/problem99.c) |
| C3 | [c3/p/problem99.c3](../../../c3/p/problem99.c3) |
| C++ | [cpp/p/problem99.cpp](../../../cpp/p/problem99.cpp) |
| Elisa | [elisa/p/problem99.elisa](../../../elisa/p/problem99.elisa) |
| Nim | [nim/p/problem99.nim](../../../nim/p/problem99.nim) |
| Odin | [odin/p/problem99.odin](../../../odin/p/problem99.odin) |
| Rust | [rust/p/problem99.rs](../../../rust/p/problem99.rs) |
| V | [v/p/problem99.v](../../../v/p/problem99.v) |
| Zig | [zig/p/problem99.zig](../../../zig/p/problem99.zig) |
