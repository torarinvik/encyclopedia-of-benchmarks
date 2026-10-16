# Ground-to-ground projectile motion

This benchmark covers the calculator methods in the pinned C++ and Java
[`ground_to_ground_projectile_motion`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/physics/ground_to_ground_projectile_motion.cpp)
and [`GroundToGroundProjectileMotion`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/GroundToGroundProjectileMotion.java)
sources. A selector adapter exposes time of flight, horizontal range, and maximum
height through one stable benchmark function.

## Contract

- Input uses the `i64_array_float64` ABI and is packed as
  `[operation, speed_micro, angle_microdegrees, auxiliary_micro]`. All scaled
  quantities use `1,000,000` units per physical unit.
- `operation` 0 returns time of flight using `auxiliary_micro` as gravity;
  operation 1 returns horizontal range using it as elapsed time; operation 2
  returns maximum height using it as gravity. These are the source methods'
  direct formulas, including the optional gravity parameter where present.
- Speed is in `[0, 1,000]` m/s and angle is in `[-360, 360]` degrees. Gravity
  must be in `[0.001, 100]` m/s² for operations 0 and 2. Elapsed time must be in
  `[0, 1,000]` seconds for operation 1. The standard gravity value is exactly
  representable in the packed decimal scale as `9,806,650`.
- Invalid selectors, out-of-range values, malformed lengths, and null input
  return `-1e300`. The parser admits up to five values for a one-extra-value
  malformed case; valid input has exactly four.
- Bounded inputs keep all outputs finite. The workload includes default and
  custom gravity, arbitrary flight time, zero speed/time, negative launch
  angles, edge angles, each operation, and malformed values.

The C++ source's `horizontal_range` takes an arbitrary elapsed time. The Java
source exposes the matching overloads for time of flight and maximum height;
the selector adapter uses their shared formulas without rounding intermediate
values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/ground_to_ground_projectile_motion.c`](../../../c/g/ground_to_ground_projectile_motion.c) |
| C3 | [`c3/g/ground_to_ground_projectile_motion.c3`](../../../c3/g/ground_to_ground_projectile_motion.c3) |
| C++ | [`cpp/g/ground_to_ground_projectile_motion.cpp`](../../../cpp/g/ground_to_ground_projectile_motion.cpp) |
| Elisa | [`elisa/g/ground_to_ground_projectile_motion.elisa`](../../../elisa/g/ground_to_ground_projectile_motion.elisa) |
| Nim | [`nim/g/ground_to_ground_projectile_motion.nim`](../../../nim/g/ground_to_ground_projectile_motion.nim) |
| Odin | [`odin/g/ground_to_ground_projectile_motion.odin`](../../../odin/g/ground_to_ground_projectile_motion.odin) |
| Rust | [`rust/g/ground_to_ground_projectile_motion.rs`](../../../rust/g/ground_to_ground_projectile_motion.rs) |
| V | [`v/g/ground_to_ground_projectile_motion.v`](../../../v/g/ground_to_ground_projectile_motion.v) |
| Zig | [`zig/g/ground_to_ground_projectile_motion.zig`](../../../zig/g/ground_to_ground_projectile_motion.zig) |

The workload is [`workload.json`](workload.json), and the oracle is
[`ground_to_ground_projectile_motion_oracle.py`](../../ground_to_ground_projectile_motion_oracle.py).
