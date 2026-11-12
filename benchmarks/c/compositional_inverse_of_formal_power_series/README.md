# Compositional Inverse of a Formal Power Series

This package computes the first `N` coefficients of the unique series `g`
with `f(g(x)) = g(f(x)) = x mod x^N` over `F_998244353`.

## Bounded contract

The `i64_array_bytes_output` call accepts `[N, a_0, ..., a_(N-1)]`, with
`2<=N<=16`, `a_0=0`, `a_1` nonzero modulo 998244353, and every coefficient in
`[0,998244352]`. It returns N little-endian signed 64-bit residues
`b_0,...,b_(N-1)` and status `8*N` bytes. Malformed input returns `-1`; a
null output buffer or capacity below `8*N` returns `-2` without writes. The
maximum valid input has 17 words, the maximum parseable input has 18 words,
the output is at most 128 bytes, and workspace is bounded at 2,176 bytes.

## Algorithm and distinctness

With `g_0=0` and `g_1=a_1^(-1)`, for each `n>=2`, the coefficient of `x^n`
in `f(g(x))` gives

`g_n = -a_1^(-1) * sum(a_k * [x^n]g(x)^k, k=2..n) mod 998244353`.

The ports maintain the needed coefficients of powers of `g` incrementally,
using a triangular recurrence with at most 1,015 convolution terms plus 105
outer coefficient accumulations at `N=16`. This is a bounded direct method;
it does not claim the official `N<=8000` scale or fast-polynomial
complexity. The independent oracle uses Lagrange inversion
`b_n=(1/n)[t^(n-1)](t/f(t))^n`, expanded from `f(t)/t` with truncated
polynomial products.

This solves for a series under composition. The nearby
[`composition_of_formal_power_series`](../composition_of_formal_power_series/README.md)
package evaluates a supplied composition, and
[`inv_of_formal_power_series`](../../i/inv_of_formal_power_series/README.md)
computes a multiplicative reciprocal. Neither solves the compositional
inverse problem.

## Provenance and rights

The operation, input conditions, field, and official bound come from Library
Checker's [Compositional Inverse of Formal Power Series task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/compositional_inverse_of_formal_power_series/task.md),
its [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/compositional_inverse_of_formal_power_series/info.toml),
and the upstream [Apache-2.0 license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The local bound, recurrence, fixtures, oracles, docs, and ports are clean-room
work based on the mathematical operation; no upstream source, prose, tests,
or expected outputs were reused. See [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) contains fixtures and ABI bounds.
[`verify_workload.py`](verify_workload.py) statically checks fixture/oracle
agreement, rights, and source inventory without launching ports. Shared suite
registration is complete in the `i64_array_bytes_output` runner and verifier.
No programs, tests, checkers, builds, compilers, or benchmarks were run during
suite integration.

## Ports

| Language | Source |
|---|---|
| C | [`c/c/compositional_inverse_of_formal_power_series.c`](../../../c/c/compositional_inverse_of_formal_power_series.c) |
| C3 | [`c3/c/compositional_inverse_of_formal_power_series.c3`](../../../c3/c/compositional_inverse_of_formal_power_series.c3) |
| C++ | [`cpp/c/compositional_inverse_of_formal_power_series.cpp`](../../../cpp/c/compositional_inverse_of_formal_power_series.cpp) |
| Elisa | [`elisa/c/compositional_inverse_of_formal_power_series.elisa`](../../../elisa/c/compositional_inverse_of_formal_power_series.elisa) |
| Mojo | [`mojo/c/compositional_inverse_of_formal_power_series.mojo`](../../../mojo/c/compositional_inverse_of_formal_power_series.mojo) |
| Nim | [`nim/c/compositional_inverse_of_formal_power_series.nim`](../../../nim/c/compositional_inverse_of_formal_power_series.nim) |
| Odin | [`odin/c/compositional_inverse_of_formal_power_series.odin`](../../../odin/c/compositional_inverse_of_formal_power_series.odin) |
| Rust | [`rust/c/compositional_inverse_of_formal_power_series.rs`](../../../rust/c/compositional_inverse_of_formal_power_series.rs) |
| V | [`v/c/compositional_inverse_of_formal_power_series.v`](../../../v/c/compositional_inverse_of_formal_power_series.v) |
| Zig | [`zig/c/compositional_inverse_of_formal_power_series.zig`](../../../zig/c/compositional_inverse_of_formal_power_series.zig) |
