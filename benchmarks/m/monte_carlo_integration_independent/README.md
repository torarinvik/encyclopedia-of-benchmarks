# Monte Carlo integration with independent draws

This benchmark follows the pinned Julia implementation's independent-sample loop. It replaces each call to `rand()` with one explicit draw and fixes the integrand to `f(x) = x*x`, so every language receives the same deterministic input while retaining Julia's one-draw-per-sample behavior.

## Contract

Input is the signed 64-bit integer array `[a_micro, b_micro, n, u0_micro, ...]`. Divide `a_micro`, `b_micro`, and each draw by `1e6` to obtain binary64 values. The bounds must lie in `[-10,000,000, 10,000,000]` micro-units and satisfy `a < b`. `n` is an integer from 1 through 16. Each `u_micro` is from 0 through 999,999 inclusive, representing one uniform draw in `[0,1)`. The input must contain exactly `3 + n` integers; the maximum valid length is 19 and the maximum parseable length is 20.

Set `interval = b - a` and `delta = interval/n`. For each supplied draw in order, compute `x = a + interval*u` and add `x*x` to the running total. Return `delta*total`, preserving Julia's interval division before accumulation and multiplication after accumulation. The output is one finite binary64 value, compared with absolute and relative tolerances of `1e-12`.

Malformed framing, a null input pointer (probed with declared length 3), a sample count outside 1..16, bounds outside the declared range or with `a >= b`, or a draw outside 0..999,999 returns `-1e300`. The scalar ABI has no output buffer checks.

The deterministic oracle is [`../../monte_carlo_integration_independent_oracle.py`](../../monte_carlo_integration_independent_oracle.py); [`workload.json`](workload.json) records the fixtures and invalid-input cases.

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/monte_carlo_integration_independent.c`](../../../c/m/monte_carlo_integration_independent.c) |
| C3 | [`c3/m/monte_carlo_integration_independent.c3`](../../../c3/m/monte_carlo_integration_independent.c3) |
| C++ | [`cpp/m/monte_carlo_integration_independent.cpp`](../../../cpp/m/monte_carlo_integration_independent.cpp) |
| Elisa | [`elisa/m/monte_carlo_integration_independent.elisa`](../../../elisa/m/monte_carlo_integration_independent.elisa) |
| Nim | [`nim/m/monte_carlo_integration_independent.nim`](../../../nim/m/monte_carlo_integration_independent.nim) |
| Odin | [`odin/m/monte_carlo_integration_independent.odin`](../../../odin/m/monte_carlo_integration_independent.odin) |
| Rust | [`rust/m/monte_carlo_integration_independent.rs`](../../../rust/m/monte_carlo_integration_independent.rs) |
| V | [`v/m/monte_carlo_integration_independent.v`](../../../v/m/monte_carlo_integration_independent.v) |
| Zig | [`zig/m/monte_carlo_integration_independent.zig`](../../../zig/m/monte_carlo_integration_independent.zig) |

## Pinned source

- Julia [`monte_carlo_integration.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/monte_carlo_integration.jl).
