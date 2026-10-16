# Project Euler Problem 20: Factorial digit sum

## Contract

Return the sum of the decimal digits of `n!` for `n` in `0..=100`. Values outside that range return `-1`.

The ports keep the factorial in little-endian base-10 digits and multiply it by each factor from 2 through `n`. They take O(n² log n) time and O(n log n) space within this fixed domain. The 200-digit buffer holds the 158-digit value of 100!.

## Workload

[`workload.json`](workload.json) covers 0!, 1!, 2!, 5!, the 10! example, 20!, the canonical 100! result, and invalid bounds.

## TheAlgorithms reference

- Go [`Problem20`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_20/problem20.go) computes `n!` with `math/big`, converts it to decimal text, and sums its digits. Its recursive helper returns zero for negative input; this benchmark bounds the intended factorial domain to 0..100.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem20.c](../../../c/p/problem20.c) |
| C3 | [c3/p/problem20.c3](../../../c3/p/problem20.c3) |
| C++ | [cpp/p/problem20.cpp](../../../cpp/p/problem20.cpp) |
| Elisa | [elisa/p/problem20.elisa](../../../elisa/p/problem20.elisa) |
| Nim | [nim/p/problem20.nim](../../../nim/p/problem20.nim) |
| Odin | [odin/p/problem20.odin](../../../odin/p/problem20.odin) |
| Rust | [rust/p/problem20.rs](../../../rust/p/problem20.rs) |
| V | [v/p/problem20.v](../../../v/p/problem20.v) |
| Zig | [zig/p/problem20.zig](../../../zig/p/problem20.zig) |
