# Project Euler Problem 92: Square Digit Chains

## Contract

For a bound from 0 through 10,000,000, count the positive starting integers below `number` whose repeated sum of squared decimal digits eventually reaches 89. The counted starts satisfy `1 ≤ start < number`; zero is excluded. Invalid bounds return -1.

The ports preserve the pinned source's digit-DP approach. They count zero-padded decimal strings for `number - 1`, grouped by whether each prefix still equals the bound or is already smaller. A precomputed endpoint check classifies each possible digit-square sum; sum zero is excluded because it represents only the starting value zero.

The source example is `number=100 → 80`. The default bound of 10,000,000 returns **8581146**.

## Workload

[`workload.json`](workload.json) covers empty and small bounds, the source example, the canonical default, and invalid limits. The digit DP has work proportional to the number of input digits and possible digit-square sums, so measurement uses 100 calls per sample.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_092/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem92 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem92/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem92.c](../../../c/p/problem92.c) |
| C3 | [c3/p/problem92.c3](../../../c3/p/problem92.c3) |
| C++ | [cpp/p/problem92.cpp](../../../cpp/p/problem92.cpp) |
| Elisa | [elisa/p/problem92.elisa](../../../elisa/p/problem92.elisa) |
| Nim | [nim/p/problem92.nim](../../../nim/p/problem92.nim) |
| Odin | [odin/p/problem92.odin](../../../odin/p/problem92.odin) |
| Rust | [rust/p/problem92.rs](../../../rust/p/problem92.rs) |
| V | [v/p/problem92.v](../../../v/p/problem92.v) |
| Zig | [zig/p/problem92.zig](../../../zig/p/problem92.zig) |
