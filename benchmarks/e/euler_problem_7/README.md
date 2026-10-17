# Project Euler problem 7

This benchmark ports the pinned C solution that finds the 10,001st prime. The
no-input `main` is adapted to a bounded prime ordinal, so the source case at
10,001 is preserved and smaller ordinals exercise the same sieve operation.

## Contract

The `i64_array_scalar` input is `[prime_ordinal]`, where the ordinal is in
1..10,001 and exactly one signed 64-bit input word is supplied. The algorithm
uses a sieve with the source's fixed exclusive upper bound of 1,000,000,
counting each unmarked number from 2 until it reaches the requested prime.
The scalar result is that prime. The source case at ordinal 10,001 returns
104743. Malformed input returns `-1`.

The independent oracle locates the requested prime by trial division. The
workload covers the first, sixth, and source ordinals, plus invalid count,
length, and trailing-word cases.

## Pinned source

- TheAlgorithms/C [`project_euler/problem_7/sol.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_7/sol.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`

The source allocates a byte sieve of length 1,000,000, scans upward from 2,
counts each unmarked value, and marks its multiples starting at twice that
value. It stops at the 10,001st prime and prints the result. The ordinal input
is a benchmark wrapper around that no-input program; the source ordinal
reproduces its fixed search exactly.

## Workload

The workload is [`workload.json`](workload.json); the independent oracle is
[`benchmarks/euler_problem_7_oracle.py`](../../euler_problem_7_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/euler_problem_7.c`](../../../c/e/euler_problem_7.c) |
| C3 | [`c3/e/euler_problem_7.c3`](../../../c3/e/euler_problem_7.c3) |
| C++ | [`cpp/e/euler_problem_7.cpp`](../../../cpp/e/euler_problem_7.cpp) |
| Elisa | [`elisa/e/euler_problem_7.elisa`](../../../elisa/e/euler_problem_7.elisa) |
| Nim | [`nim/e/euler_problem_7.nim`](../../../nim/e/euler_problem_7.nim) |
| Odin | [`odin/e/euler_problem_7.odin`](../../../odin/e/euler_problem_7.odin) |
| Rust | [`rust/e/euler_problem_7.rs`](../../../rust/e/euler_problem_7.rs) |
| V | [`v/e/euler_problem_7.v`](../../../v/e/euler_problem_7.v) |
| Zig | [`zig/e/euler_problem_7.zig`](../../../zig/e/euler_problem_7.zig) |
