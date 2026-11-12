# Power of a formal power series

This package implements Library Checker `pow_of_formal_power_series`. Given
the first `N` coefficients of `f(x)` and a nonnegative integer `M`, it returns
the first `N` coefficients of `f(x)^M` over `F_998244353`.

## Bounded contract

The `i64_array_bytes_output` ABI accepts `[N,M,a_0,...,a_(N-1)]`, with
`1<=N<=32`, `0<=M<=1000000000000000000`, and coefficients in
`0..998244352`. Success writes exactly `N` little-endian signed 64-bit
coefficients and returns `8*N` bytes. Invalid input returns `-1`; valid input
with a null output or capacity below `8*N` returns `-2` without writes. The
maximum input is 34 words and the maximum output is 256 bytes.

Each port computes the truncated product modulo `x^N` and uses binary
repeated squaring. This costs `O(N^2 log(M+1))` coefficient operations at the
local bound and does not claim the official `N<=500000` scale.

## Distinctness

This operation accepts any constant coefficient and exponent, including
`M=0`; when `M=0`, the result is the multiplicative identity. In contrast,
[`exp_of_formal_power_series`](../../e/exp_of_formal_power_series/README.md)
requires zero constant input, while
[`log_of_formal_power_series`](../../l/log_of_formal_power_series/README.md)
requires constant coefficient one. Neither computes arbitrary integral
powers or covers the zero-constant valuation cases. The primary oracle uses
truncated repeated squaring. The independent oracle factors
`f=x^v*a_v*(1+h)` and expands
`a_v^M*x^(vM)*(1+h)^M` by the binomial theorem, handling `M=0`, the zero
series, and `v*M>=N` explicitly.

## Source and rights

Official statement: [Library Checker — Pow of Formal Power Series](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/pow_of_formal_power_series/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/pow_of_formal_power_series/info.toml)
(`N_MAX=500000`, `M_MAX=10^18`, `MOD=998244353`). The task repository is
Apache-2.0; see [RIGHTS.md](RIGHTS.md). The local profile, ports, fixtures,
and oracles are clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). Root-level byte-output suite
registration is complete in the `i64_array_bytes_output` runner and verifier.
No programs, tests, checkers, builds, compilers, or benchmarks were run during
suite integration.

| Language | Source |
|---|---|
| C | [c/p/pow_of_formal_power_series.c](../../../c/p/pow_of_formal_power_series.c) |
| C3 | [c3/p/pow_of_formal_power_series.c3](../../../c3/p/pow_of_formal_power_series.c3) |
| C++ | [cpp/p/pow_of_formal_power_series.cpp](../../../cpp/p/pow_of_formal_power_series.cpp) |
| Elisa | [elisa/p/pow_of_formal_power_series.elisa](../../../elisa/p/pow_of_formal_power_series.elisa) |
| Mojo | [mojo/p/pow_of_formal_power_series.mojo](../../../mojo/p/pow_of_formal_power_series.mojo) |
| Nim | [nim/p/pow_of_formal_power_series.nim](../../../nim/p/pow_of_formal_power_series.nim) |
| Odin | [odin/p/pow_of_formal_power_series.odin](../../../odin/p/pow_of_formal_power_series.odin) |
| Rust | [rust/p/pow_of_formal_power_series.rs](../../../rust/p/pow_of_formal_power_series.rs) |
| V | [v/p/pow_of_formal_power_series.v](../../../v/p/pow_of_formal_power_series.v) |
| Zig | [zig/p/pow_of_formal_power_series.zig](../../../zig/p/pow_of_formal_power_series.zig) |
