# Projectile Motion

This package ports the bounded trajectory calculation from the pinned Java [`ProjectileMotion`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/ProjectileMotion.java) source. It computes the time of flight, horizontal range, and maximum height for a projectile launched from an initial height under a supplied gravity value.

The float64 input is `[initial_velocity, launch_angle_degrees, initial_height, gravity]`. Velocity and height are finite values in `[0, 1000]`, angle is in `[-180, 180]` degrees, and gravity is in `[0.1, 20]`. The output is `[time_of_flight, horizontal_range, maximum_height]`. The ports preserve the source formula order and use its maximum-height rule: if the initial vertical velocity is positive, add the height gained to the initial height; otherwise return the initial height.

Invalid input returns `-1` without writing output. A null or undersized output buffer returns `-2`, also without writing. Results use absolute tolerance `1e-9` and relative tolerance `1e-12` to account for small differences in standard-library trigonometric functions, including the cosine residue at vertical launch angles. The independent oracle and workload are in [`projectile_motion_oracle.py`](../../projectile_motion_oracle.py) and [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | [`c/p/projectile_motion.c`](../../../c/p/projectile_motion.c) |
| C3 | [`c3/p/projectile_motion.c3`](../../../c3/p/projectile_motion.c3) |
| C++ | [`cpp/p/projectile_motion.cpp`](../../../cpp/p/projectile_motion.cpp) |
| Elisa | [`elisa/p/projectile_motion.elisa`](../../../elisa/p/projectile_motion.elisa) |
| Nim | [`nim/p/projectile_motion.nim`](../../../nim/p/projectile_motion.nim) |
| Odin | [`odin/p/projectile_motion.odin`](../../../odin/p/projectile_motion.odin) |
| Rust | [`rust/p/projectile_motion.rs`](../../../rust/p/projectile_motion.rs) |
| V | [`v/p/projectile_motion.v`](../../../v/p/projectile_motion.v) |
| Zig | [`zig/p/projectile_motion.zig`](../../../zig/p/projectile_motion.zig) |
