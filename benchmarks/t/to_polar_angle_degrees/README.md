# Cartesian to Polar Angle in Degrees

This package returns only the `theta` output of the pinned MATLAB/Octave `topolar(x, y)` helper. Input is the finite binary64 pair `[x, y]`, each within `[-1,000,000, 1,000,000]`. The origin is invalid because the source evaluates `0/0` and produces NaN; invalid input returns `-1e300`.

The angle follows the source formula exactly: `atan(y / x)`, with `pi` added when `x < 0`, then multiplied by `180 / pi`. It is not normalized to `[0, 360)`: positive-x lower-quadrant inputs return negative angles, while negative-x lower-quadrant inputs return angles above 180 degrees. At the axes, the source gives 90 degrees for `(0, y>0)`, -90 for `(0, y<0)`, and 180 for `(x<0, 0)`. IEEE signed zero is preserved through the comparison and division in the source formula.

The source also returns radius. That separate output is already represented by component `0` of [`cartesian_to_polar`](../../c/cartesian_to_polar/README.md); this package covers theta only and uses degrees, while the existing angle component there uses radians and `atan2` semantics.

| Language | Port |
|---|---|
| C | [`c/t/to_polar_angle_degrees.c`](../../../c/t/to_polar_angle_degrees.c) |
| C3 | [`c3/t/to_polar_angle_degrees.c3`](../../../c3/t/to_polar_angle_degrees.c3) |
| C++ | [`cpp/t/to_polar_angle_degrees.cpp`](../../../cpp/t/to_polar_angle_degrees.cpp) |
| Elisa | [`elisa/t/to_polar_angle_degrees.elisa`](../../../elisa/t/to_polar_angle_degrees.elisa) |
| Nim | [`nim/t/to_polar_angle_degrees.nim`](../../../nim/t/to_polar_angle_degrees.nim) |
| Odin | [`odin/t/to_polar_angle_degrees.odin`](../../../odin/t/to_polar_angle_degrees.odin) |
| Rust | [`rust/t/to_polar_angle_degrees.rs`](../../../rust/t/to_polar_angle_degrees.rs) |
| V | [`v/t/to_polar_angle_degrees.v`](../../../v/t/to_polar_angle_degrees.v) |
| Zig | [`zig/t/to_polar_angle_degrees.zig`](../../../zig/t/to_polar_angle_degrees.zig) |

Pinned source: [TheAlgorithms/MATLAB-Octave `to_polar.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/to_polar.m). See [`workload.json`](workload.json) for all quadrants, signed-zero axes, bounds, and the undefined origin.
