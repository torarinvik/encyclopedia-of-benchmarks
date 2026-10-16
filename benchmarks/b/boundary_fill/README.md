# Boundary fill

Fill the region reachable from a seed pixel until pixels with the boundary color are reached. The pinned Java method checks the eight neighboring pixels (including diagonals), mutates the image in place, and skips pixels already equal to the fill or boundary color.

Pinned source: [TheAlgorithms/Java `BoundaryFill.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/BoundaryFill.java).

## Contract

Input is `[width, height, start_x, start_y, new_color, boundary_color, pixels...]`. Pixel storage is x-major, matching Java's `image[x][y]` access. Dimensions are 1 through 32; coordinates are zero-based; colors are signed 32-bit integers. The fill uses 8-connectivity, stops at boundary-color pixels, and leaves pixels already equal to `new_color` unchanged.

The Java source checks lower bounds but omits upper-bound checks, so a fill that reaches the image edge can throw. The portable contract bounds every neighbor lookup and treats positions outside the image as non-fillable. Invalid inputs return `-1`; insufficient output capacity returns `-2`. The result is the complete x-major image as little-endian signed 64-bit values.

## Workload and build

[`workload.json`](workload.json) covers enclosed fills, diagonal connectivity, fills that reach image edges, already-filled/boundary seeds, equal fill and boundary colors, invalid input, and capacity failure. Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm boundary_fill --language LANGUAGE`; record with `python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/boundary_fill/LANGUAGE/build.json`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/boundary_fill.c`](../../../c/b/boundary_fill.c) |
| C3 | [`c3/b/boundary_fill.c3`](../../../c3/b/boundary_fill.c3) |
| C++ | [`cpp/b/boundary_fill.cpp`](../../../cpp/b/boundary_fill.cpp) |
| Elisa | [`elisa/b/boundary_fill.elisa`](../../../elisa/b/boundary_fill.elisa) |
| Nim | [`nim/b/boundary_fill.nim`](../../../nim/b/boundary_fill.nim) |
| Odin | [`odin/b/boundary_fill.odin`](../../../odin/b/boundary_fill.odin) |
| Rust | [`rust/b/boundary_fill.rs`](../../../rust/b/boundary_fill.rs) |
| V | [`v/b/boundary_fill.v`](../../../v/b/boundary_fill.v) |
| Zig | [`zig/b/boundary_fill.zig`](../../../zig/b/boundary_fill.zig) |
