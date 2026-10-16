# Project Euler Problem 87

## Contract

The pinned Python source counts distinct values below `limit` that equal the sum of one prime square, one prime cube, and one prime fourth power. The source derives candidate primes from `sqrt(limit - 24)` and bounds the limit at 50,000,000 for the canonical problem. The benchmark accepts limits from 24 through 50,000,000; limits below 24 or above that bound return `-1` because the pinned source cannot form its prime bound or exceeds the benchmark's fixed memory ceiling.

The ports use an ascending prime sieve and a packed bitset, so repeated representations count once. The source statement example gives 4 values below 50; the canonical result below 50,000,000 is 1,097,343.

Each language exports `int64_t problem87(int64_t limit)`.

## Workload

[`workload.json`](workload.json) includes the lower bound, nearby values, statement example, canonical limit, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_087/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem87.c](../../../c/p/problem87.c) |
| C3 | [c3/p/problem87.c3](../../../c3/p/problem87.c3) |
| C++ | [cpp/p/problem87.cpp](../../../cpp/p/problem87.cpp) |
| Elisa | [elisa/p/problem87.elisa](../../../elisa/p/problem87.elisa) |
| Nim | [nim/p/problem87.nim](../../../nim/p/problem87.nim) |
| Odin | [odin/p/problem87.odin](../../../odin/p/problem87.odin) |
| Rust | [rust/p/problem87.rs](../../../rust/p/problem87.rs) |
| V | [v/p/problem87.v](../../../v/p/problem87.v) |
| Zig | [zig/p/problem87.zig](../../../zig/p/problem87.zig) |
