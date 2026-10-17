# Simpson integration

This package adapts the pinned Java and JavaScript composite Simpson implementations to their shared integrand `f(x) = exp(-x) * (4 - x^2)`. Each call returns one binary64 result.

## Contract

- ABI: `i64_array_float64`, with packed input `[N, a_micro, b_micro]`; endpoints are divided by 1,000,000.
- `N` must be even and in `[2, 128]`. Endpoints must be in `[-10, 10]` and satisfy `a <= b`. Equal endpoints return `0.0`.
- The implementations compute `h = (b-a)/N`, visit `N+1` samples in ascending index order, and increment `x` by repeated addition after each sample. Endpoint samples have weight 1, odd interior samples weight 4, and even interior samples weight 2. The result is `(h/3) * weighted_sum`.
- Invalid input returns `-1e300`. Valid output uses absolute and relative tolerances of `1e-12`.

The pinned Java method stores sample values in an ordered map and prints per-index diagnostics; those prints are outside the benchmark result contract. The JavaScript version receives the same fixed integrand as a callback and returns zero for equal endpoints. Both source implementations use repeated `x += h`, so the ports preserve that sampling order rather than recomputing each point as `a + i*h`.

## Workload and source

[`workload.json`](workload.json) includes the Java example interval, zero-width and signed intervals, endpoint bounds, the maximum interval count, and malformed inputs. The independent [oracle](../../simpson_integration_oracle.py) reproduces the pinned sample sequence, weights, and accumulation order.

- [Java `SimpsonIntegration.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SimpsonIntegration.java)
- [JavaScript `SimpsonIntegration.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SimpsonIntegration.js)

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/simpson_integration.c`](../../../c/s/simpson_integration.c) |
| C3 | [`c3/s/simpson_integration.c3`](../../../c3/s/simpson_integration.c3) |
| C++ | [`cpp/s/simpson_integration.cpp`](../../../cpp/s/simpson_integration.cpp) |
| Elisa | [`elisa/s/simpson_integration.elisa`](../../../elisa/s/simpson_integration.elisa) |
| Nim | [`nim/s/simpson_integration.nim`](../../../nim/s/simpson_integration.nim) |
| Odin | [`odin/s/simpson_integration.odin`](../../../odin/s/simpson_integration.odin) |
| Rust | [`rust/s/simpson_integration.rs`](../../../rust/s/simpson_integration.rs) |
| V | [`v/s/simpson_integration.v`](../../../v/s/simpson_integration.v) |
| Zig | [`zig/s/simpson_integration.zig`](../../../zig/s/simpson_integration.zig) |
