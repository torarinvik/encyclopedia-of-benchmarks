# Three-dimensional graph drawing by the moment curve

This package implements the explicit moment-curve construction described in David R. Wood's *Encyclopedia of Algorithms* chapter “Three-Dimensional Graph Drawing,” DOI [`10.1007/978-1-4939-2864-4_656`](https://doi.org/10.1007/978-1-4939-2864-4_656). Number vertices from 1 through `n` and place vertex `i` at `(i,i²,i³)`.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n]`, with `0 <= n <= 64`.
- Output is `[n,x1,y1,z1,...,xn,yn,zn]` as little-endian signed-i64 words, where `(xi,yi,zi)=(i,i²,i³)` for one-based vertex IDs. The graph's edge set is not needed to assign points: every simple graph on these vertices is drawn by selecting its edges from the complete straight-line graph on the same point set.
- Maximum output is 193 words (1,544 bytes); all coordinate values fit signed 64-bit integers. Invalid input returns `-1`; null or short output returns `-2` without writes.
- This is a source-defined non-crossing drawing construction, not a small-volume optimization algorithm. The chapter motivates volume minimization; the moment curve is an example establishing that every graph has a 3D straight-line grid drawing.

## Provenance and rights

Source attribution: David R. Wood, “Three-Dimensional Graph Drawing,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_656`. The chapter and summarized papers remain copyrighted. This clean-room package copies no source code, prose, or figures and asserts no source-code license. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary coordinate oracle](../../three_dimensional_moment_curve_oracle.py)
- [independent recurrence verifier oracle](../../three_dimensional_moment_curve_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/g/three_dimensional_moment_curve.c`](../../../c/g/three_dimensional_moment_curve.c) |
| C3 | [`c3/g/three_dimensional_moment_curve.c3`](../../../c3/g/three_dimensional_moment_curve.c3) |
| C++ | [`cpp/g/three_dimensional_moment_curve.cpp`](../../../cpp/g/three_dimensional_moment_curve.cpp) |
| Elisa | [`elisa/g/three_dimensional_moment_curve.elisa`](../../../elisa/g/three_dimensional_moment_curve.elisa) |
| Nim | [`nim/g/three_dimensional_moment_curve.nim`](../../../nim/g/three_dimensional_moment_curve.nim) |
| Odin | [`odin/g/three_dimensional_moment_curve.odin`](../../../odin/g/three_dimensional_moment_curve.odin) |
| Rust | [`rust/g/three_dimensional_moment_curve.rs`](../../../rust/g/three_dimensional_moment_curve.rs) |
| V | [`v/g/three_dimensional_moment_curve.v`](../../../v/g/three_dimensional_moment_curve.v) |
| Zig | [`zig/g/three_dimensional_moment_curve.zig`](../../../zig/g/three_dimensional_moment_curve.zig) |
