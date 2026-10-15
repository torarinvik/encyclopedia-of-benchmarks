# Area under curve

## Contract

This benchmark applies the composite trapezoidal rule to one of three fixed sample functions. Input is `[function_id, start_milli, end_milli, step_count]`; coordinates are integer thousandths, and the interval endpoints are sorted before integration. Function IDs are `0: f(x)=5`, `1: f(x)=x`, and `2: f(x)=x²`. Coordinates are in `[0, 100]`; step count is in `[1, 10,000]`. Invalid shape, function ID, coordinate, or step count returns `-1`.

For `h=(end-start)/step_count`, the result is the nearest micro-unit to `h/2 * Σ(f(xᵢ)+f(xᵢ₊₁))`. The fixed function set and thousandth-coordinate encoding adapt the upstream callback interface to the shared integer-array ABI. The selected functions stay nonnegative on the input domain, so the upstream absolute-value term is equivalent to the standard trapezoid area. The Rust source sorts reversed endpoints and requires at least one step; this benchmark uses those rules where the Python source differs.

## Workload and reproduction

The workload covers constant, linear, and quadratic functions; coarse and refined step counts; reversed and zero-width intervals; fractional coordinates; and maximum bounds.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm area_under_curve --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/a/area_under_curve/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/area_under_curve.c`](../../../c/a/area_under_curve.c) |
| C3 | [`c3/a/area_under_curve.c3`](../../../c3/a/area_under_curve.c3) |
| C++ | [`cpp/a/area_under_curve.cpp`](../../../cpp/a/area_under_curve.cpp) |
| Elisa | [`elisa/a/area_under_curve.elisa`](../../../elisa/a/area_under_curve.elisa) |
| Nim | [`nim/a/area_under_curve.nim`](../../../nim/a/area_under_curve.nim) |
| Odin | [`odin/a/area_under_curve.odin`](../../../odin/a/area_under_curve.odin) |
| Rust | [`rust/a/area_under_curve.rs`](../../../rust/a/area_under_curve.rs) |
| V | [`v/a/area_under_curve.v`](../../../v/a/area_under_curve.v) |
| Zig | [`zig/a/area_under_curve.zig`](../../../zig/a/area_under_curve.zig) |

## TheAlgorithms references

- [Python `area_under_curve.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/area_under_curve.py)
- [Rust `area_under_curve.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/area_under_curve.rs)
