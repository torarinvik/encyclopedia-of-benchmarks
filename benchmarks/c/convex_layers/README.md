# Convex Layers (Onion Decomposition)

This benchmark repeatedly removes the boundary of a planar point set and returns the number of convex layers. It is a distinct iterative geometry workload from a single convex-hull computation: each peel exposes a new set whose hull must be found.

## Contract

- Input is `[N, x0, y0, ..., xN-1, yN-1]`, with `0 <= N <= 64` and each coordinate in `[-1,000,000, 1,000,000]`.
- Duplicate coordinates are treated as one geometric point.
- A layer contains every distinct point on the current convex-hull boundary, including points collinear along a hull edge. If the remaining set is collinear, all of its points form its final layer.
- Return the number of layers. The empty set returns zero; malformed input returns `-1`.
- The implementation uses insertion sort and monotone chains for each remaining set, then checks all points against hull edges. For this bounded contract the worst-case time is `O(N^3)` and auxiliary storage is `O(N)`.

The independent oracle uses exhaustive supporting-line enumeration rather than monotone chains. This makes the workload checks structurally separate from the benchmark method.

[`workload.json`](workload.json) covers empty, singleton, duplicate, collinear, edge-collinear, nested, malformed, coordinate-boundary, and maximum-size sets.

## Language ports

The package has ports in all ten current languages.

| Language | Source |
| --- | --- |
| C | [c/c/convex_layers.c](../../../c/c/convex_layers.c) |
| C3 | [c3/c/convex_layers.c3](../../../c3/c/convex_layers.c3) |
| C++ | [cpp/c/convex_layers.cpp](../../../cpp/c/convex_layers.cpp) |
| Elisa | [elisa/c/convex_layers.elisa](../../../elisa/c/convex_layers.elisa) |
| Mojo | [mojo/c/convex_layers.mojo](../../../mojo/c/convex_layers.mojo) |
| Nim | [nim/c/convex_layers.nim](../../../nim/c/convex_layers.nim) |
| Odin | [odin/c/convex_layers.odin](../../../odin/c/convex_layers.odin) |
| Rust | [rust/c/convex_layers.rs](../../../rust/c/convex_layers.rs) |
| V | [v/c/convex_layers.v](../../../v/c/convex_layers.v) |
| Zig | [zig/c/convex_layers.zig](../../../zig/c/convex_layers.zig) |

## Reference

- [A Simple Convex Layers Algorithm](https://arxiv.org/abs/1702.06829), for the convex-layer decomposition problem and its repeated-hull definition. This benchmark is a clean-room bounded implementation and does not reuse the paper's text or code.
