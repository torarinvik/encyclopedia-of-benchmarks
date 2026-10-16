# Gravitational force

Compute the two-dimensional force vector using the pinned Java source's operation order. Inputs are `[mass1,x1,y1,mass2,x2,y2]`; masses are zero or have magnitude from `1e-12` through `1e12`, and positions lie in `[-1e6,1e6]`. Coincident positions return `[0,0]`; otherwise the squared separation must be at least `1e-12`. The source formula uses `G = 6.67430e-11`, `dx = x1 - x2`, `dy = y1 - y2`, and returns `[G*m1*m2/distanceSquared * dx/distance, G*m1*m2/distanceSquared * dy/distance]`.

The `float64_slice_io` ABI returns two binary64 outputs. Invalid inputs return `-1`; a null or undersized output buffer returns `-2`. The independent oracle, workload, and tolerances are in [`gravitational_force_oracle.py`](../../gravitational_force_oracle.py) and [`workload.json`](workload.json). The implementation is based on Java's pinned [`Gravitation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/Gravitation.java).

| Language | Port |
|---|---|
| C | [`c/g/gravitational_force.c`](../../../c/g/gravitational_force.c) |
| C3 | [`c3/g/gravitational_force.c3`](../../../c3/g/gravitational_force.c3) |
| C++ | [`cpp/g/gravitational_force.cpp`](../../../cpp/g/gravitational_force.cpp) |
| Elisa | [`elisa/g/gravitational_force.elisa`](../../../elisa/g/gravitational_force.elisa) |
| Nim | [`nim/g/gravitational_force.nim`](../../../nim/g/gravitational_force.nim) |
| Odin | [`odin/g/gravitational_force.odin`](../../../odin/g/gravitational_force.odin) |
| Rust | [`rust/g/gravitational_force.rs`](../../../rust/g/gravitational_force.rs) |
| V | [`v/g/gravitational_force.v`](../../../v/g/gravitational_force.v) |
| Zig | [`zig/g/gravitational_force.zig`](../../../zig/g/gravitational_force.zig) |

Use `python3 benchmarks/verify_float64_slice_io.py --algorithm gravitational_force` to check the ports against the independent oracle and ABI boundary cases.
