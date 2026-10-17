# Project Euler problem 6

This benchmark ports the pinned C solution that finds the difference between
the square of the sum and the sum of squares for the integers 1 through 100.
The no-input `main` is adapted to an explicit upper-bound argument: `n=100`
reproduces the source loop exactly, while smaller values use the same loop over
1 through `n`.

## Contract

The `i64_array_scalar` input is `[n]`, with `n` in 1..100 and exactly one
signed 64-bit input word. The result is `(1 + ... + n)^2 - (1^2 + ... + n^2)`.
The source-exact result for `n=100` is 25164150. Malformed input returns `-1`.

The oracle uses the closed-form identity
`n(n+1)(3n^2-n-2)/12`, independent of the source's loop accumulation. The
workload includes boundary and representative valid inputs, plus invalid
range and framing cases.

## Pinned source

- TheAlgorithms/C [`project_euler/problem_6/sol.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_6/sol.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`

The source loops from 1 through 100 inclusive, accumulating the sum of squares
and the sum, then returns `sum^2 - sum_of_squares`. The bounded `n=100`
operation follows those exact loop bounds. `euler_problem_4` and
`euler_problem_7` remain separate candidates.

## Workload

The workload is [`workload.json`](workload.json); the closed-form oracle is
[`benchmarks/euler_problem_6_oracle.py`](../../euler_problem_6_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/e/euler_problem_6.c`](../../../c/e/euler_problem_6.c) |
| C3 | [`c3/e/euler_problem_6.c3`](../../../c3/e/euler_problem_6.c3) |
| C++ | [`cpp/e/euler_problem_6.cpp`](../../../cpp/e/euler_problem_6.cpp) |
| Elisa | [`elisa/e/euler_problem_6.elisa`](../../../elisa/e/euler_problem_6.elisa) |
| Nim | [`nim/e/euler_problem_6.nim`](../../../nim/e/euler_problem_6.nim) |
| Odin | [`odin/e/euler_problem_6.odin`](../../../odin/e/euler_problem_6.odin) |
| Rust | [`rust/e/euler_problem_6.rs`](../../../rust/e/euler_problem_6.rs) |
| V | [`v/e/euler_problem_6.v`](../../../v/e/euler_problem_6.v) |
| Zig | [`zig/e/euler_problem_6.zig`](../../../zig/e/euler_problem_6.zig) |
