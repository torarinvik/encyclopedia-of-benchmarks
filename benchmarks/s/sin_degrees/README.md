# Sine approximation in degrees

Approximate sine for an angle measured in degrees with the pinned Python Taylor series.

## Contract

- Uses the unary binary64 ABI: `double sin_degrees(double angle_degrees)`.
- Finite inputs in `[-1,000,000, 1,000,000]` are accepted. Non-finite and out-of-range values return `-1.0`.
- Reduce the angle with `angle - floor(angle / 360) * 360`, then convert degrees to radians.
- Start with the radian value and add 18 alternating Taylor terms for powers 3 through 37, dividing each term by that power's factorial.
- Round the final value to 10 decimal places. The approximation can return `-1.0` for a valid angle such as `-90`; the input domain distinguishes that result from invalid input.
- The bound keeps degree reduction and all Taylor intermediates finite in binary64.

## Source semantics

This package follows the `sin` function in the pinned [TheAlgorithms/Python `sin.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sin.py). That function accepts degrees, reduces full turns, converts to radians, performs 18 Taylor additions by default, and rounds to 10 decimal places by default. The bounded unary contract makes those defaults fixed for the benchmark. This implementation is distinct from [`sin_radians`](../sin_radians/README.md), which follows Go's radians-based Bhaskara approximation.

## Workload and build

[`workload.json`](workload.json) covers the pinned examples, quadrant values, negative degrees, full turns, both finite input bounds, and invalid finite values outside the domain. Results are compared with relative tolerance `1e-12` and absolute tolerance `1e-12`.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm sin_degrees --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/sin_degrees/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sin_degrees.c`](../../../c/s/sin_degrees.c) |
| C3 | [`c3/s/sin_degrees.c3`](../../../c3/s/sin_degrees.c3) |
| C++ | [`cpp/s/sin_degrees.cpp`](../../../cpp/s/sin_degrees.cpp) |
| Elisa | [`elisa/s/sin_degrees.elisa`](../../../elisa/s/sin_degrees.elisa) |
| Nim | [`nim/s/sin_degrees.nim`](../../../nim/s/sin_degrees.nim) |
| Odin | [`odin/s/sin_degrees.odin`](../../../odin/s/sin_degrees.odin) |
| Rust | [`rust/s/sin_degrees.rs`](../../../rust/s/sin_degrees.rs) |
| V | [`v/s/sin_degrees.v`](../../../v/s/sin_degrees.v) |
| Zig | [`zig/s/sin_degrees.zig`](../../../zig/s/sin_degrees.zig) |
