# Project Euler Problem 120: Square Remainders

## Contract

For an inclusive upper bound from 0 through 1,000, return the sum of the maximum remainders for each `a` from 3 through that bound when `(a-1)^n + (a+1)^n` is divided by `a²`. Bounds below 3 produce the empty sum 0. Invalid bounds return -1.

The pinned source uses the closed form `r_max(a) = 2*a*((a-1)//2)`. For the odd-power remainder, it maximizes `2*a*n` subject to `2*a*n < a²`, giving `n <= (a-1)//2`. Even powers give remainder 2. All ports preserve that integer formula and inclusive sum bound.

The source examples are `10 → 300` and `100 → 330750`; the default bound 1,000 returns **333082500**.

## Workload

[`workload.json`](workload.json) covers empty and lower-bound sums, the source examples, the canonical default, and invalid limits.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_120/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem120 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem120/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem120.c](../../../c/p/problem120.c) |
| C3 | [c3/p/problem120.c3](../../../c3/p/problem120.c3) |
| C++ | [cpp/p/problem120.cpp](../../../cpp/p/problem120.cpp) |
| Elisa | [elisa/p/problem120.elisa](../../../elisa/p/problem120.elisa) |
| Nim | [nim/p/problem120.nim](../../../nim/p/problem120.nim) |
| Odin | [odin/p/problem120.odin](../../../odin/p/problem120.odin) |
| Rust | [rust/p/problem120.rs](../../../rust/p/problem120.rs) |
| V | [v/p/problem120.v](../../../v/p/problem120.v) |
| Zig | [zig/p/problem120.zig](../../../zig/p/problem120.zig) |
