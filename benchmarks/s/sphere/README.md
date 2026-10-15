# Sphere volume and surface area

This package ports both methods in the pinned [TheAlgorithms/JavaScript `Sphere` class](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Sphere.js). Mode 0 computes volume with `(radius³ × π × 4) / 3`; mode 1 computes surface area with `radius² × π × 4`.

The `i64_array_float64` ABI accepts `[mode, radius]`, with mode 0 or 1 and integer radius 0..1,000,000. Invalid shape or values return `-1e300`. The bound keeps input integral and intermediate magnitude finite while covering both source methods.

[`workload.json`](workload.json) covers both formulas, zero and unit radii, larger values, the maximum radius, and invalid inputs.

The shared float64 runner checks the ordered volume and surface-area formulas with relative and absolute tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sphere.c`](../../../c/s/sphere.c) |
| C3 | [`c3/s/sphere.c3`](../../../c3/s/sphere.c3) |
| C++ | [`cpp/s/sphere.cpp`](../../../cpp/s/sphere.cpp) |
| Elisa | [`elisa/s/sphere.elisa`](../../../elisa/s/sphere.elisa) |
| Nim | [`nim/s/sphere.nim`](../../../nim/s/sphere.nim) |
| Odin | [`odin/s/sphere.odin`](../../../odin/s/sphere.odin) |
| Rust | [`rust/s/sphere.rs`](../../../rust/s/sphere.rs) |
| V | [`v/s/sphere.v`](../../../v/s/sphere.v) |
| Zig | [`zig/s/sphere.zig`](../../../zig/s/sphere.zig) |
