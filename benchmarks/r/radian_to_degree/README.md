# Radian to degree

Convert an angle from radians to degrees using the pinned JavaScript expression.

## Contract

- The `float64_unary` ABI accepts a finite binary64 radian value in `[-1,000,000, 1,000,000]` and returns binary64 degrees.
- Values outside that normalized domain return `-1e300`. Valid results use relative and absolute tolerance `1e-12`.
- The implementation preserves the source operation order `radian * (180 / pi)`.

## Source semantics

This follows the pinned [TheAlgorithms JavaScript `RadianToDegree.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/RadianToDegree.js). The source computes radians multiplied by 180 divided by π, using the grouped factor `180 / π`; its documentation example contains a unit-label typo, but the function parameter and formula both describe radians to degrees.

## Workload

[`workload.json`](workload.json) includes zero, positive and negative angles, a half turn, a full turn, fractional values, range endpoints, and out-of-range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/radian_to_degree.c`](../../../c/r/radian_to_degree.c) |
| C3 | [`c3/r/radian_to_degree.c3`](../../../c3/r/radian_to_degree.c3) |
| C++ | [`cpp/r/radian_to_degree.cpp`](../../../cpp/r/radian_to_degree.cpp) |
| Elisa | [`elisa/r/radian_to_degree.elisa`](../../../elisa/r/radian_to_degree.elisa) |
| Nim | [`nim/r/radian_to_degree.nim`](../../../nim/r/radian_to_degree.nim) |
| Odin | [`odin/r/radian_to_degree.odin`](../../../odin/r/radian_to_degree.odin) |
| Rust | [`rust/r/radian_to_degree.rs`](../../../rust/r/radian_to_degree.rs) |
| V | [`v/r/radian_to_degree.v`](../../../v/r/radian_to_degree.v) |
| Zig | [`zig/r/radian_to_degree.zig`](../../../zig/r/radian_to_degree.zig) |

The package uses the `float64_unary` benchmark ABI.
