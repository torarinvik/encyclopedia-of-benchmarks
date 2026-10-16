# Circular orbit velocity

Compute the speed required for a stable circular orbit from `[centralMass,radius]`, using the pinned Java source's formula `sqrt(G*centralMass/radius)` with `G = 6.67430e-11`. The benchmark domain is finite positive masses from `1e-12` through `1e25` and radii from `1e-12` through `1e12`; nonpositive inputs are invalid, matching the source's exception condition.

The `float64_slice_io` ABI returns one binary64 output. Invalid inputs return `-1`; a null or undersized output buffer returns `-2`. The independent oracle, workload, and tolerances are in [`circular_orbit_velocity_oracle.py`](../../circular_orbit_velocity_oracle.py) and [`workload.json`](workload.json). The implementation is based on Java's pinned [`Gravitation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/Gravitation.java).

| Language | Port |
|---|---|
| C | [`c/c/circular_orbit_velocity.c`](../../../c/c/circular_orbit_velocity.c) |
| C3 | [`c3/c/circular_orbit_velocity.c3`](../../../c3/c/circular_orbit_velocity.c3) |
| C++ | [`cpp/c/circular_orbit_velocity.cpp`](../../../cpp/c/circular_orbit_velocity.cpp) |
| Elisa | [`elisa/c/circular_orbit_velocity.elisa`](../../../elisa/c/circular_orbit_velocity.elisa) |
| Nim | [`nim/c/circular_orbit_velocity.nim`](../../../nim/c/circular_orbit_velocity.nim) |
| Odin | [`odin/c/circular_orbit_velocity.odin`](../../../odin/c/circular_orbit_velocity.odin) |
| Rust | [`rust/c/circular_orbit_velocity.rs`](../../../rust/c/circular_orbit_velocity.rs) |
| V | [`v/c/circular_orbit_velocity.v`](../../../v/c/circular_orbit_velocity.v) |
| Zig | [`zig/c/circular_orbit_velocity.zig`](../../../zig/c/circular_orbit_velocity.zig) |

Use `python3 benchmarks/verify_float64_slice_io.py --algorithm circular_orbit_velocity` to check the ports against the independent oracle and ABI boundary cases.
