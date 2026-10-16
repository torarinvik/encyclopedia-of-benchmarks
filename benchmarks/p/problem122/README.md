# Project Euler Problem 122

## Contract

For an inclusive maximum from 0 through 200, return the sum of the minimum addition-chain lengths for every target from 1 through that maximum. Targets 0 and 1 contribute zero; invalid maxima return `-1`.

The pinned Python source searches star addition chains in depth-first order. At each step it adds the current chain's last value to each earlier element in chain order, and the first successful chain at the first successful depth determines the length. The ports preserve that search order and the bound. The source examples return **45** for 14 and **50** for 15; the canonical result for 200 is **1582**.

## Workload

[`workload.json`](workload.json) covers the empty and unit prefixes, source examples, intermediate and canonical bounds, and invalid signed-64-bit inputs.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_122/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem122.c](../../../c/p/problem122.c) |
| C3 | [c3/p/problem122.c3](../../../c3/p/problem122.c3) |
| C++ | [cpp/p/problem122.cpp](../../../cpp/p/problem122.cpp) |
| Elisa | [elisa/p/problem122.elisa](../../../elisa/p/problem122.elisa) |
| Nim | [nim/p/problem122.nim](../../../nim/p/problem122.nim) |
| Odin | [odin/p/problem122.odin](../../../odin/p/problem122.odin) |
| Rust | [rust/p/problem122.rs](../../../rust/p/problem122.rs) |
| V | [v/p/problem122.v](../../../v/p/problem122.v) |
| Zig | [zig/p/problem122.zig](../../../zig/p/problem122.zig) |
