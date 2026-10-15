# Cartesian to polar coordinates

This package benchmarks the `to_polar(x, y, &radius, &theta)` transformation in the pinned [TheAlgorithms/C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/cartesian_to_polar.c). It covers both outputs: radius is `sqrt(x * x + y * y)`, and angle is `atan2(y, x)` in radians.

The `float64_triple` ABI accepts `[x, y, component]`. Component `0` returns the radius; component `1` returns the angle. The inputs `x` and `y` must be finite and within `[-1,000,000, 1,000,000]`. The selector must be exactly `0` or `1`. These bounds keep the source-order sum of squares and its square root finite. Invalid ABI inputs return `-1e300`, which does not collide with any valid radius or angle.

The pinned C helper applies quadrant adjustments that can disagree with `atan2(y, x)`, including on the negative x-axis. Its own test compares the angle against `atan2(y, x)` within `0.01`. The benchmark follows that tested mathematical contract and records the upstream quadrant defect here. At the zero vector, where direction is undefined, the benchmark defines the selected angle as `0.0` for a deterministic result.

Runtime and auxiliary space are O(1). The workload covers both output components in every quadrant, axis and origin cases, the bounded radius, and invalid selectors and coordinates.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cartesian_to_polar.c`](../../../c/c/cartesian_to_polar.c) |
| C3 | [`c3/c/cartesian_to_polar.c3`](../../../c3/c/cartesian_to_polar.c3) |
| C++ | [`cpp/c/cartesian_to_polar.cpp`](../../../cpp/c/cartesian_to_polar.cpp) |
| Elisa | [`elisa/c/cartesian_to_polar.elisa`](../../../elisa/c/cartesian_to_polar.elisa) |
| Nim | [`nim/c/cartesian_to_polar.nim`](../../../nim/c/cartesian_to_polar.nim) |
| Odin | [`odin/c/cartesian_to_polar.odin`](../../../odin/c/cartesian_to_polar.odin) |
| Rust | [`rust/c/cartesian_to_polar.rs`](../../../rust/c/cartesian_to_polar.rs) |
| V | [`v/c/cartesian_to_polar.v`](../../../v/c/cartesian_to_polar.v) |
| Zig | [`zig/c/cartesian_to_polar.zig`](../../../zig/c/cartesian_to_polar.zig) |
