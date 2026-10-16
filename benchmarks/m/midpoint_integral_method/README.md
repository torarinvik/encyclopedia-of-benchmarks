# Midpoint integral method

## Contract

Approximate the definite integral of one of four pinned functions with the midpoint rule. Packed input is `[function_id, N, a_milli, b_milli]`: function IDs 0..3 select `f`, `g`, `k`, and `l`; `N` is an even interval count from 2 through 64; and `a_milli` and `b_milli` encode endpoints divided by 1000, with `0 <= a_milli < b_milli <= 10000`.

The functions are:

- `f(x) = sqrt(x) + ln(x)`
- `g(x) = exp(-x) * (4 - x^2)`
- `k(x) = sqrt(2*x^3 + 3)`
- `l(x) = x + ln(2*x + 1)`

Set `h = (b-a)/N`, then visit the midpoints in source order using an incremented `xi`: start at `xi=a`, add `func(xi + h/2)` to a sequential sum, and increment `xi` by `h` for each interval. Return `h * sum`. The first midpoint is positive even when `a=0`, keeping all function evaluations in their real domains. Invalid input returns `-1e300`.

The C++ source comment requires an even `N`. The benchmark enforces that documented condition. Its CLI uses one `N`, `a`, and `b` for all four functions; the benchmark selects one function per call so each result fits the scalar binary64 ABI.

## Workload

Cases and expected values are in [`workload.json`](workload.json). The workload uses the `i64_array_float64` ABI with absolute and relative tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/midpoint_integral_method.c`](../../../c/m/midpoint_integral_method.c) |
| C3 | [`c3/m/midpoint_integral_method.c3`](../../../c3/m/midpoint_integral_method.c3) |
| C++ | [`cpp/m/midpoint_integral_method.cpp`](../../../cpp/m/midpoint_integral_method.cpp) |
| Elisa | [`elisa/m/midpoint_integral_method.elisa`](../../../elisa/m/midpoint_integral_method.elisa) |
| Nim | [`nim/m/midpoint_integral_method.nim`](../../../nim/m/midpoint_integral_method.nim) |
| Odin | [`odin/m/midpoint_integral_method.odin`](../../../odin/m/midpoint_integral_method.odin) |
| Rust | [`rust/m/midpoint_integral_method.rs`](../../../rust/m/midpoint_integral_method.rs) |
| V | [`v/m/midpoint_integral_method.v`](../../../v/m/midpoint_integral_method.v) |
| Zig | [`zig/m/midpoint_integral_method.zig`](../../../zig/m/midpoint_integral_method.zig) |

## TheAlgorithms references

- [C++ `midpoint_integral_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/midpoint_integral_method.cpp)
- [C++-1 `midpoint_integral_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/midpoint_integral_method.cpp)
