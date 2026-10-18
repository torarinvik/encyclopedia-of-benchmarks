# Monte Carlo integration with antithetic pairs

This benchmark follows the pinned Java implementation's seeded sampling loop. It replaces `Random.nextDouble()` with explicit draws and fixes the integrand to `f(x) = x*x`, so every language receives the same deterministic input while retaining Java's antithetic pairing.

## Contract

Input is the signed 64-bit integer array `[a_micro, b_micro, n, u0_micro, ...]`. Divide `a_micro`, `b_micro`, and each draw by `1e6` to obtain binary64 values. The bounds must lie in `[-10,000,000, 10,000,000]` micro-units and satisfy `a < b`. `n` is an integer from 1 through 16. Each `u_micro` is from 0 through 999,999 inclusive, representing one uniform draw in `[0,1)`. The input must contain exactly `3 + ceil(n/2)` integers; the maximum valid length is 11 and the maximum parseable length is 12.

Set `interval = b - a`. For every pair, consume one draw `u`, compute `x1 = a + u*interval` and then `x2 = a + (1-u)*interval`, and add `x1*x1` followed by `x2*x2` to the running total. If `n` is odd, consume one final draw and add `(a + u*interval)^2`. Return `interval*total/n`, preserving the source multiplication and division order. The output is one finite binary64 value, compared with absolute and relative tolerances of `1e-12`.

Malformed framing, a null input pointer, a sample count outside 1..16, bounds outside the declared range or with `a >= b`, or a draw outside 0..999,999 returns `-1e300`. The null-input workload probe uses a declared length of 3. The scalar ABI has no output buffer checks.

The deterministic oracle is [`../../monte_carlo_integration_oracle.py`](../../monte_carlo_integration_oracle.py); [`workload.json`](workload.json) records the fixtures and invalid-input cases.

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/monte_carlo_integration.c`](../../../c/m/monte_carlo_integration.c) |
| C3 | [`c3/m/monte_carlo_integration.c3`](../../../c3/m/monte_carlo_integration.c3) |
| C++ | [`cpp/m/monte_carlo_integration.cpp`](../../../cpp/m/monte_carlo_integration.cpp) |
| Elisa | [`elisa/m/monte_carlo_integration.elisa`](../../../elisa/m/monte_carlo_integration.elisa) |
| Nim | [`nim/m/monte_carlo_integration.nim`](../../../nim/m/monte_carlo_integration.nim) |
| Odin | [`odin/m/monte_carlo_integration.odin`](../../../odin/m/monte_carlo_integration.odin) |
| Rust | [`rust/m/monte_carlo_integration.rs`](../../../rust/m/monte_carlo_integration.rs) |
| V | [`v/m/monte_carlo_integration.v`](../../../v/m/monte_carlo_integration.v) |
| Zig | [`zig/m/monte_carlo_integration.zig`](../../../zig/m/monte_carlo_integration.zig) |

## Pinned source

- Java [`MonteCarloIntegration.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/randomized/MonteCarloIntegration.java), seeded `approximate` overload and its `doApproximate` loop.
