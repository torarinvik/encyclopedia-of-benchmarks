# Pyramid geometry

The pinned JavaScript `Pyramid` class computes volume and surface area for a regular square pyramid. Volume is `(base_side² * height) / 3`; surface area is `base_side² + ((base_side * 4) / 2) * sqrt((base_side / 2)² + height²)`.

## Contract

Input is `[operation, base_side_milli, height_milli]`, where operation 0 selects volume and 1 selects surface area. Both dimensions are positive thousandths in `1..10_000_000` (0.001 to 10,000 units). Output is binary64. Invalid input returns `-1e300`.

The fixed-point encoding gives deterministic integer input while retaining fractional dimensions. See [`workload.json`](workload.json), the runtime [oracle](../../pyramid_oracle.py), and the [pinned JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Pyramid.js).

| Language | Port |
|---|---|
| C | [`c/p/pyramid.c`](../../../c/p/pyramid.c) |
| C3 | [`c3/p/pyramid.c3`](../../../c3/p/pyramid.c3) |
| C++ | [`cpp/p/pyramid.cpp`](../../../cpp/p/pyramid.cpp) |
| Elisa | [`elisa/p/pyramid.elisa`](../../../elisa/p/pyramid.elisa) |
| Nim | [`nim/p/pyramid.nim`](../../../nim/p/pyramid.nim) |
| Odin | [`odin/p/pyramid.odin`](../../../odin/p/pyramid.odin) |
| Rust | [`rust/p/pyramid.rs`](../../../rust/p/pyramid.rs) |
| V | [`v/p/pyramid.v`](../../../v/p/pyramid.v) |
| Zig | [`zig/p/pyramid.zig`](../../../zig/p/pyramid.zig) |
