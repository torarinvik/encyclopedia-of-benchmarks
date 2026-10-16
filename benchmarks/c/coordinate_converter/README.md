# Coordinate converter

This benchmark covers both conversion methods in the pinned Java
[`CoordinateConverter`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/CoordinateConverter.java): Cartesian to polar and polar to Cartesian.

## Contract

- The `float64_triple` input is `[first, second, component]`.
- Components `0` and `1` select the radius and angle in degrees from Cartesian
  coordinates `(x, y)`. Inputs must be finite and within `[-1,000,000, 1,000,000]`.
- Components `2` and `3` select Cartesian `x` and `y` from polar coordinates
  `(radius, angle_degrees)`. Radius must be in `[0, 1,000,000]` and angle in
  `[-36,000, 36,000]` degrees.
- The formulas preserve the Java methods: `sqrt(x*x + y*y)`,
  `toDegrees(atan2(y,x))`, `radius*cos(toRadians(angle))`, and
  `radius*sin(toRadians(angle))`. At the origin, the angle is zero.
- An unknown selector, non-finite value, or value outside the selected
  component's bounds returns `-1e300`.
- The Cartesian-to-polar angle is in degrees, as in this Java source. It is
  distinct from the existing C `cartesian_to_polar` benchmark, which reports
  radians.

The independent oracle is
[`coordinate_converter_oracle.py`](../../coordinate_converter_oracle.py).
The workload exercises both methods, all quadrants and axes, the origin,
degree-based polar inputs, bounds, and invalid selectors.

## Pinned source

The Java source revision is
[`CoordinateConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/CoordinateConverter.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm coordinate_converter --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/c/coordinate_converter/rust/build.json
python3 benchmarks/verify_float64_triple.py --algorithm coordinate_converter --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/coordinate_converter.c`](../../../c/c/coordinate_converter.c) |
| C3 | [`c3/c/coordinate_converter.c3`](../../../c3/c/coordinate_converter.c3) |
| C++ | [`cpp/c/coordinate_converter.cpp`](../../../cpp/c/coordinate_converter.cpp) |
| Elisa | [`elisa/c/coordinate_converter.elisa`](../../../elisa/c/coordinate_converter.elisa) |
| Nim | [`nim/c/coordinate_converter.nim`](../../../nim/c/coordinate_converter.nim) |
| Odin | [`odin/c/coordinate_converter.odin`](../../../odin/c/coordinate_converter.odin) |
| Rust | [`rust/c/coordinate_converter.rs`](../../../rust/c/coordinate_converter.rs) |
| V | [`v/c/coordinate_converter.v`](../../../v/c/coordinate_converter.v) |
| Zig | [`zig/c/coordinate_converter.zig`](../../../zig/c/coordinate_converter.zig) |
