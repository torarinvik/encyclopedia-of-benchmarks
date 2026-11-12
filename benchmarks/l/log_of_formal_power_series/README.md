# Logarithm of a Formal Power Series

This package computes the first `N` coefficients of the formal logarithm of a
series over `F_998244353`. The constant coefficient must be one.

## Bounded contract

The `i64_array_bytes_output` call accepts `[N, a_0, ..., a_(N-1)]` with
`1<=N<=64`, every coefficient in `[0,998244352]`, and `a_0=1`. It returns the
first `N` coefficients of `log(f(x))` modulo `x^N`, as little-endian signed
64-bit residues. Success returns `8*N` bytes. Invalid input returns `-1`; a
null or undersized output returns `-2` without writes. The profile keeps the
official modulus and operation, with a much smaller local bound than the
official `N<=500000`.

## Algorithm and distinctness

From `f'=f*g'` with `g=log(f)` and `f_0=1`, coefficient `n` obeys

`n*g_n = n*f_n - sum(i*g_i*f_(n-i), i=1..n-1) mod 998244353`.

The ports use this quadratic coefficient recurrence and modular inverses of
the degree. It differs from [`inv_of_formal_power_series`](../i/inv_of_formal_power_series/README.md),
which requires only a nonzero constant and solves for a reciprocal, and from
[`exp_of_formal_power_series`](../e/exp_of_formal_power_series/README.md),
which requires a zero constant and uses `g'=f'g` to compute an exponential.
The local [`logarithmic_series`](../logarithmic_series/README.md) workload
formats scalar logarithmic-expansion terms as text; it does not compute a
finite-field formal-series logarithm.
The primary oracle uses the recurrence above. The independent oracle evaluates
`log(1+h)=sum((-1)^(k+1)*h^k/k)` by direct truncated polynomial products.

## Provenance and rights

The operation, unit-constant condition, field, and official bound come from
Library Checker's [Log of Formal Power Series task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/log_of_formal_power_series/task.md),
its [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/log_of_formal_power_series/info.toml),
and the upstream [Apache-2.0 license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The local ports, workload, and oracles are clean-room implementations based
on the mathematical operation; no upstream code, prose, tests, or expected
outputs were copied. See [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) lists the fixtures and ABI bounds.
[`verify_workload.py`](verify_workload.py) statically checks fixtures,
oracles, rights, and source paths without launching ports.

## Ports

| Language | Source |
|---|---|
| C | [`c/l/log_of_formal_power_series.c`](../../../c/l/log_of_formal_power_series.c) |
| C3 | [`c3/l/log_of_formal_power_series.c3`](../../../c3/l/log_of_formal_power_series.c3) |
| C++ | [`cpp/l/log_of_formal_power_series.cpp`](../../../cpp/l/log_of_formal_power_series.cpp) |
| Elisa | [`elisa/l/log_of_formal_power_series.elisa`](../../../elisa/l/log_of_formal_power_series.elisa) |
| Mojo | [`mojo/l/log_of_formal_power_series.mojo`](../../../mojo/l/log_of_formal_power_series.mojo) |
| Nim | [`nim/l/log_of_formal_power_series.nim`](../../../nim/l/log_of_formal_power_series.nim) |
| Odin | [`odin/l/log_of_formal_power_series.odin`](../../../odin/l/log_of_formal_power_series.odin) |
| Rust | [`rust/l/log_of_formal_power_series.rs`](../../../rust/l/log_of_formal_power_series.rs) |
| V | [`v/l/log_of_formal_power_series.v`](../../../v/l/log_of_formal_power_series.v) |
| Zig | [`zig/l/log_of_formal_power_series.zig`](../../../zig/l/log_of_formal_power_series.zig) |

The workload is registered with the shared byte-output runner and verifier. No
programs, tests, or checkers were run during suite integration.
