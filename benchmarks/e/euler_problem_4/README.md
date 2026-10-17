# Project Euler problem 4

This benchmark ports the pinned C solution that finds the largest palindrome
made from the product of two three-digit numbers. The no-input `main` is
adapted to a small explicit digit-count argument: three digits reproduce the
source search exactly, while one- and two-digit inputs use the same search over
their corresponding factor ranges.

## Contract

The `i64_array_scalar` input is `[digit_count]`, with `digit_count` in 1..3 and
exactly one signed 64-bit input word. For `d` digits, both factors range
independently from `10^(d-1)` through `10^d - 1`, inclusive. A product is
palindromic when its decimal digits read the same in either direction. The
scalar result is the largest palindromic product. The three-digit result is
906609, matching the pinned source. Malformed input returns `-1`; valid inputs
always have at least one palindromic product.

The independent oracle enumerates all factor pairs and takes the maximum
palindromic product. The workload includes all three valid digit counts and
invalid count, length, and trailing-word cases.

## Pinned source

- TheAlgorithms/C [`project_euler/problem_4/sol.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_4/sol.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`

The source scans both loop variables from 100 through 999, multiplies each
pair, reverses the decimal digits to test for a palindrome, and retains the
largest product. The bounded three-digit operation follows those exact ranges.
The input digit count is a benchmark wrapper around that no-input program;
`euler_problem_6` and `euler_problem_7` remain separate candidates.

## Workload

The workload is [`workload.json`](workload.json); the direct enumeration
oracle is [`benchmarks/euler_problem_4_oracle.py`](../../euler_problem_4_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/euler_problem_4.c`](../../../c/e/euler_problem_4.c) |
| C3 | [`c3/e/euler_problem_4.c3`](../../../c3/e/euler_problem_4.c3) |
| C++ | [`cpp/e/euler_problem_4.cpp`](../../../cpp/e/euler_problem_4.cpp) |
| Elisa | [`elisa/e/euler_problem_4.elisa`](../../../elisa/e/euler_problem_4.elisa) |
| Nim | [`nim/e/euler_problem_4.nim`](../../../nim/e/euler_problem_4.nim) |
| Odin | [`odin/e/euler_problem_4.odin`](../../../odin/e/euler_problem_4.odin) |
| Rust | [`rust/e/euler_problem_4.rs`](../../../rust/e/euler_problem_4.rs) |
| V | [`v/e/euler_problem_4.v`](../../../v/e/euler_problem_4.v) |
| Zig | [`zig/e/euler_problem_4.zig`](../../../zig/e/euler_problem_4.zig) |
