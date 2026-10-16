# Midpoint integration

The pinned JavaScript function divides `[a,b]` into `N` equal panels, evaluates the supplied function at each midpoint `a+i*h+h/2`, sums those values, and multiplies by `h`. This benchmark specializes the callback to three deterministic integrands: `1`, `x`, and `x²`.

## Contract

Input is `[function_id, N, a_micro, b_micro]` in the `i64_array_bytes_output` ABI. Function IDs 0, 1, and 2 select `1`, `x`, and `x²`. `N` is 1 through 256; bounds satisfy `-1 <= a <= b <= 1` and use scale 1,000,000. The output is the integral rounded to a signed integer at scale 1,000,000,000, encoded as little-endian i64. Success returns 8 bytes, malformed input returns `-1`, and insufficient capacity returns `-2`. The source’s equal-bound case returns zero.

The scaled encoding keeps this numerical integration benchmark deterministic across languages while preserving the midpoint arithmetic. Workload points avoid half-unit output ties.

Pinned source: [TheAlgorithms/JavaScript `MidpointIntegration.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MidpointIntegration.js). [`workload.json`](workload.json) covers each integrand, one-panel and multi-panel cases, equal bounds, and invalid inputs. Runtime oracle: [`benchmarks/midpoint_integration_oracle.py`](../../midpoint_integration_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/midpoint_integration.c`](../../../c/m/midpoint_integration.c) |
| C3 | [`c3/m/midpoint_integration.c3`](../../../c3/m/midpoint_integration.c3) |
| C++ | [`cpp/m/midpoint_integration.cpp`](../../../cpp/m/midpoint_integration.cpp) |
| Elisa | [`elisa/m/midpoint_integration.elisa`](../../../elisa/m/midpoint_integration.elisa) |
| Nim | [`nim/m/midpoint_integration.nim`](../../../nim/m/midpoint_integration.nim) |
| Odin | [`odin/m/midpoint_integration.odin`](../../../odin/m/midpoint_integration.odin) |
| Rust | [`rust/m/midpoint_integration.rs`](../../../rust/m/midpoint_integration.rs) |
| V | [`v/m/midpoint_integration.v`](../../../v/m/midpoint_integration.v) |
| Zig | [`zig/m/midpoint_integration.zig`](../../../zig/m/midpoint_integration.zig) |
