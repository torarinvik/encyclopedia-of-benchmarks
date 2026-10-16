# Project Euler Problem 190: Maximising a Weighted Product

## Contract

For an inclusive bound `n` from 0 through 15, return the sum of `floor(P_m)` for `m = 2..n`, where `P_m = x_1 x_2² ... x_m^m` is maximized subject to positive `x_i` summing to `m`. Bounds below 2 produce the empty sum 0; invalid bounds return -1.

The pinned source derives `x_i = i * 2/(m+1)`, then computes each weighted product in ascending `i` order using binary64 exponentiation and adds the truncated positive product. The ports retain that multiplication order. The source examples return `2 -> 1`, `3 -> 2`, `4 -> 4`, and `5 -> 10`; the canonical bound 15 returns **371048281**.

## Workload

[`workload.json`](workload.json) covers the empty sum, all documented examples, the canonical bound, and invalid bounds.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_190/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem190 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem190/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem190.c](../../../c/p/problem190.c) |
| C3 | [c3/p/problem190.c3](../../../c3/p/problem190.c3) |
| C++ | [cpp/p/problem190.cpp](../../../cpp/p/problem190.cpp) |
| Elisa | [elisa/p/problem190.elisa](../../../elisa/p/problem190.elisa) |
| Nim | [nim/p/problem190.nim](../../../nim/p/problem190.nim) |
| Odin | [odin/p/problem190.odin](../../../odin/p/problem190.odin) |
| Rust | [rust/p/problem190.rs](../../../rust/p/problem190.rs) |
| V | [v/p/problem190.v](../../../v/p/problem190.v) |
| Zig | [zig/p/problem190.zig](../../../zig/p/problem190.zig) |
