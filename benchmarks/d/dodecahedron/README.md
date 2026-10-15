# Dodecahedron area and volume

Compute the surface area or volume of a regular dodecahedron from its edge length.

## Contract

- The `i64_array_float64` ABI accepts `[edge, quantity]`; quantity `0` selects surface area and `1` selects volume.
- The bounded edge domain is the positive integer range 1 through 1,000,000. This keeps the source's integer square and cube within signed 64-bit range.
- The area formula is `3 * sqrt(25 + 10 * sqrt(5)) * edge^2`; the volume formula is `((15 + 7 * sqrt(5)) / 4) * edge^3`.
- Invalid length, edge, or quantity returns `-1e300`. Valid results use relative and absolute tolerance `1e-12`.

## Source semantics

This combines both functions in the pinned [TheAlgorithms Python `dodecahedron.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/dodecahedron.py). Each source function requires a positive integer edge and raises `ValueError` otherwise. The bounded positive integer domain is a normalized subset; invalid benchmark inputs use the sentinel.

## Workload

[`workload.json`](workload.json) includes the two documented examples for both formulas, small and maximum edges, invalid edges, selectors, and array lengths.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/dodecahedron.c`](../../../c/d/dodecahedron.c) |
| C3 | [`c3/d/dodecahedron.c3`](../../../c3/d/dodecahedron.c3) |
| C++ | [`cpp/d/dodecahedron.cpp`](../../../cpp/d/dodecahedron.cpp) |
| Elisa | [`elisa/d/dodecahedron.elisa`](../../../elisa/d/dodecahedron.elisa) |
| Nim | [`nim/d/dodecahedron.nim`](../../../nim/d/dodecahedron.nim) |
| Odin | [`odin/d/dodecahedron.odin`](../../../odin/d/dodecahedron.odin) |
| Rust | [`rust/d/dodecahedron.rs`](../../../rust/d/dodecahedron.rs) |
| V | [`v/d/dodecahedron.v`](../../../v/d/dodecahedron.v) |
| Zig | [`zig/d/dodecahedron.zig`](../../../zig/d/dodecahedron.zig) |

The package uses the `i64_array_float64` benchmark ABI.
