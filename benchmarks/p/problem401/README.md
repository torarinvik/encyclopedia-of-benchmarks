# Project Euler Problem 401: sum of squares of divisors

## Contract

For an inclusive limit from 0 through 1,000, return the pinned C source's sum of `sigma2(n)` for every `n` from 0 through that limit, modulo 1,000,000,000. Limits outside the benchmark domain return `-1`.

The ports preserve the source's divisor enumeration: scan `i` from 1 while `i² <= n + 1`, add each divisor and paired quotient once, then sum squared divisor-list entries beginning at index 1. That index rule omits the first entry, which is divisor 1. The source special-cases `n=1` with a one-element divisor list, so `sigma2(1)` is 0; `sigma2(0)` is also 0. The bounded domain keeps the source's fixed-array behavior safe.

The workload includes small source-behavior examples and the source default limit of 1,000.

## Workload

[`workload.json`](workload.json) covers the omitted-divisor behavior, the default limit, modulo result, and invalid inputs.

## TheAlgorithms reference

- C [`sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_401/sol1.c)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem401.c](../../../c/p/problem401.c) |
| C3 | [c3/p/problem401.c3](../../../c3/p/problem401.c3) |
| C++ | [cpp/p/problem401.cpp](../../../cpp/p/problem401.cpp) |
| Elisa | [elisa/p/problem401.elisa](../../../elisa/p/problem401.elisa) |
| Nim | [nim/p/problem401.nim](../../../nim/p/problem401.nim) |
| Odin | [odin/p/problem401.odin](../../../odin/p/problem401.odin) |
| Rust | [rust/p/problem401.rs](../../../rust/p/problem401.rs) |
| V | [v/p/problem401.v](../../../v/p/problem401.v) |
| Zig | [zig/p/problem401.zig](../../../zig/p/problem401.zig) |
