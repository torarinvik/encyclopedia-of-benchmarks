# Secant method variants

## Contract

This benchmark preserves the two pinned secant implementations with an explicit variant selector. The packed input is `[variant, control]`.

- Variant `0` is the pinned C implementation: it applies the secant update to `f(x) = x*x - 3` from the source self-test seeds `x0 = 0.2` and `x1 = 0.5`. `control` must be `100`, representing tolerance `0.0001`. It returns the first iterate whose step is smaller than that tolerance, or the source failure value `-1` after at most 99 updates.
- Variant `1` is the pinned Python implementation: it applies the secant update to `f(x) = 8*x - 2*exp(-x)` from the source doctest seeds `x0 = 1` and `x1 = 3`. `control` is the exact update count, restricted to `0..=2`, and the result is the second seed after that many updates.

These seed and control bounds keep all valid denominator evaluations nonzero and all results finite. The Python objective is strictly increasing; its initial denominator and its first updated denominator are nonzero for the bounded source seeds. Invalid input returns the finite binary64 sentinel `-1e300`.

The workload compares binary64 results with absolute tolerance `1e-12` and zero relative tolerance. The separate MATLAB `secant` source is outside this package.

## Workload

Cases and expected results are in [`workload.json`](workload.json). The package uses the `i64_array_float64` ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/secant_method.c`](../../../c/s/secant_method.c) |
| C3 | [`c3/s/secant_method.c3`](../../../c3/s/secant_method.c3) |
| C++ | [`cpp/s/secant_method.cpp`](../../../cpp/s/secant_method.cpp) |
| Elisa | [`elisa/s/secant_method.elisa`](../../../elisa/s/secant_method.elisa) |
| Nim | [`nim/s/secant_method.nim`](../../../nim/s/secant_method.nim) |
| Odin | [`odin/s/secant_method.odin`](../../../odin/s/secant_method.odin) |
| Rust | [`rust/s/secant_method.rs`](../../../rust/s/secant_method.rs) |
| V | [`v/s/secant_method.v`](../../../v/s/secant_method.v) |
| Zig | [`zig/s/secant_method.zig`](../../../zig/s/secant_method.zig) |

## TheAlgorithms references

- [C `secant_method.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/secant_method.c)
- [Python `secant_method.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/secant_method.py)
