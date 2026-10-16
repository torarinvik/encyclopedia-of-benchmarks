# Project Euler Problem 12, solution 1

This package preserves the incremental triangular-number search used by the
pinned Python `sol1.py`. For each triangular number it counts prime-factor
multiplicities and multiplies each exponent plus one to obtain the exact
positive-divisor count.

## Contract

- The benchmark input is the fixed threshold `500`. This is the Python source's
  no-argument setting and the C source's default setting.
- Return the first triangular number with **more than** 500 positive divisors:
  `76,576,500`.
- Other inputs return the benchmark adapter sentinel `-1`; the Python source
  itself has no threshold parameter.
- The pinned C version accepts an optional threshold. Its divisor-pair loop
  visits `ceil(sqrt(n))` because it uses `i < sqrtl(n) + 1`; when that value
  divides `n`, it counts the complementary pair twice. Its `else if (i*i == n)`
  correction cannot run for perfect squares because the preceding divisibility
  branch already matches. The ports follow Python sol1's exact
  prime-multiplicity counter and fixed canonical search.

The separate `problem12` package uses prime-factorization of the two coprime
halves of a triangular number to support many thresholds. This package retains
the `sol1` search shape: advance one triangular number at a time, then factor
that whole number to count its divisors.

## Workload

[`workload.json`](workload.json) checks the sole supported threshold and
out-of-contract inputs.

## Pinned sources

- [TheAlgorithms/Python `project_euler/problem_012/sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_012/sol1.py)
- [TheAlgorithms/C `project_euler/problem_12/sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_12/sol1.c)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/problem12_sol1.c`](../../../c/p/problem12_sol1.c) |
| C3 | [`c3/p/problem12_sol1.c3`](../../../c3/p/problem12_sol1.c3) |
| C++ | [`cpp/p/problem12_sol1.cpp`](../../../cpp/p/problem12_sol1.cpp) |
| Elisa | [`elisa/p/problem12_sol1.elisa`](../../../elisa/p/problem12_sol1.elisa) |
| Nim | [`nim/p/problem12_sol1.nim`](../../../nim/p/problem12_sol1.nim) |
| Odin | [`odin/p/problem12_sol1.odin`](../../../odin/p/problem12_sol1.odin) |
| Rust | [`rust/p/problem12_sol1.rs`](../../../rust/p/problem12_sol1.rs) |
| V | [`v/p/problem12_sol1.v`](../../../v/p/problem12_sol1.v) |
| Zig | [`zig/p/problem12_sol1.zig`](../../../zig/p/problem12_sol1.zig) |

## Oracle

[`problem12_sol1_oracle.py`](../../problem12_sol1_oracle.py) computes the
threshold result by factoring the two coprime halves of each triangular number,
independently of the ports' whole-triangle factorization loop.
