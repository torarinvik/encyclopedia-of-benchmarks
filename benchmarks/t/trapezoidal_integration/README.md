# Trapezoidal integration

## Contract

This benchmark uses the `i64_array_float64` ABI and adapts the pinned Rust `trapezoidal_integral` function to two fixed callback choices. The packed input is `[start_micro,end_micro,precision,function_id]`. Endpoints are signed integer micro-units in `[-1,000,000,1,000,000]` (that is, `[-1,1]`); precision is in `[1,10,000]`; function ID `0` selects `f(x)=x²`, and ID `1` selects the signed odd function `f(x)=x³`. A valid call returns the composite trapezoidal sum as a binary64 value. Invalid length, bounds, precision, or function ID returns `-1e300`.

For `delta=(b-a)/precision`, each iteration evaluates `left=a+delta*i`, then `right=left+delta`, adds `midpoint(f(left),f(right))*delta`, and advances left-to-right in the source order. Bounds are oriented: swapping them negates the result. The cubic selector takes negative values on negative inputs. These choices distinguish this generic callback adapter from [`area_under_curve`](../area_under_curve/README.md), whose contract sorts its bounds and uses only nonnegative selectors on `[0,100]`.

The arbitrary callback in the source is represented by a bounded selector so the benchmark has a finite, reproducible cross-language input domain. The endpoints are small enough that `(left_value+right_value)/2` matches Rust's `f64::midpoint` branch without overflow.

## Pinned source

The source is [`src/math/trapezoidal_integration.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/trapezoidal_integration.rs) at commit `fed66cb0c74a939ec5163648458a8c2b46fd4c`.

[`workload.json`](workload.json) covers the source's endpoint and accumulation behavior, both function choices, reversed and zero-width intervals, negative values, precision bounds, malformed lengths, and invalid selectors.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm trapezoidal_integration --language rust --with-checker
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/t/trapezoidal_integration/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm trapezoidal_integration
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/trapezoidal_integration.c`](../../../c/t/trapezoidal_integration.c) |
| C3 | [`c3/t/trapezoidal_integration.c3`](../../../c3/t/trapezoidal_integration.c3) |
| C++ | [`cpp/t/trapezoidal_integration.cpp`](../../../cpp/t/trapezoidal_integration.cpp) |
| Elisa | [`elisa/t/trapezoidal_integration.elisa`](../../../elisa/t/trapezoidal_integration.elisa) |
| Nim | [`nim/t/trapezoidal_integration.nim`](../../../nim/t/trapezoidal_integration.nim) |
| Odin | [`odin/t/trapezoidal_integration.odin`](../../../odin/t/trapezoidal_integration.odin) |
| Rust | [`rust/t/trapezoidal_integration.rs`](../../../rust/t/trapezoidal_integration.rs) |
| V | [`v/t/trapezoidal_integration.v`](../../../v/t/trapezoidal_integration.v) |
| Zig | [`zig/t/trapezoidal_integration.zig`](../../../zig/t/trapezoidal_integration.zig) |
