# Polynomial Taylor shift

This package implements Library Checker `polynomial_taylor_shift`. Given
`f(x)=sum(a_i*x^i)` and a field element `c`, it returns the `N` coefficients
of `f(x+c)` over `F_998244353`.

## Bounded contract

The `i64_array_bytes_output` ABI accepts `[N,c,a_0,...,a_(N-1)]`, with
`1<=N<=64` and every coefficient and `c` in `0..998244352`. Success writes
exactly `N` little-endian signed 64-bit coefficients and returns `8*N` bytes,
including trailing zero coefficients. Malformed input returns `-1`; valid
input with a null output or capacity below `8*N` returns `-2` without writes.
The maximum input is 66 words and the maximum output is 512 bytes.

The ports use a descending in-place Horner recurrence. Starting with the zero
polynomial, each coefficient `a_i` updates `R(x)` to `R(x)*(x+c)+a_i`:
`R_d <- c*R_d + R_(d-1)` from high degree to low degree, then
`R_0 <- c*R_0 + a_i`. The bounded operation uses `O(N^2)` modular arithmetic;
it does not claim the official `N<=524288` scale.

## Distinctness

The local `polynomial_evaluation` profiles evaluate at one scalar point and
return one value; this task returns every coefficient after translating the
input polynomial. The local formal-series composition computes `f(g(x))`
under the condition that the inner series has zero constant term. Here the
inner expression is `x+c`, whose constant is generally nonzero, and the
result is a full-degree polynomial shift. The primary oracle uses Horner
updates; the independent oracle applies the binomial expansion
`b_j=sum_{i>=j} a_i*binom(i,j)*c^(i-j)`.

## Source and rights

Official statement: [Library Checker — Polynomial Taylor Shift](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_taylor_shift/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/polynomial_taylor_shift/info.toml)
(`N_MAX=524288`, `MOD=998244353`). The task repository is Apache-2.0; see
[RIGHTS.md](RIGHTS.md). The local profile, implementation, workload, and
oracles are clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). The workload is registered with the
shared byte-output runner and verifier. No programs, tests, or checkers were
run during suite integration.

| Language | Source |
|---|---|
| C | [c/p/polynomial_taylor_shift.c](../../../c/p/polynomial_taylor_shift.c) |
| C3 | [c3/p/polynomial_taylor_shift.c3](../../../c3/p/polynomial_taylor_shift.c3) |
| C++ | [cpp/p/polynomial_taylor_shift.cpp](../../../cpp/p/polynomial_taylor_shift.cpp) |
| Elisa | [elisa/p/polynomial_taylor_shift.elisa](../../../elisa/p/polynomial_taylor_shift.elisa) |
| Mojo | [mojo/p/polynomial_taylor_shift.mojo](../../../mojo/p/polynomial_taylor_shift.mojo) |
| Nim | [nim/p/polynomial_taylor_shift.nim](../../../nim/p/polynomial_taylor_shift.nim) |
| Odin | [odin/p/polynomial_taylor_shift.odin](../../../odin/p/polynomial_taylor_shift.odin) |
| Rust | [rust/p/polynomial_taylor_shift.rs](../../../rust/p/polynomial_taylor_shift.rs) |
| V | [v/p/polynomial_taylor_shift.v](../../../v/p/polynomial_taylor_shift.v) |
| Zig | [zig/p/polynomial_taylor_shift.zig](../../../zig/p/polynomial_taylor_shift.zig) |
