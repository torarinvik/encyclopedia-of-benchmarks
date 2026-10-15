# Triangle centers

This package ports the `Triangle` geometry class from the pinned [TheAlgorithms/Python `geometry/triangle.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/triangle.py). One call computes the circumcenter, incenter, and orthocenter of three 2D vertices.

## Contract

- Input is `[x1,y1,x2,y2,x3,y3]` in signed 64-bit integers, with coordinates in `[-100,100]`.
- The bounded domain requires three noncollinear points, pairwise distinct x coordinates, and `y3` different from `y1` and `y2`. This keeps the source's slope and orthocenter divisions finite. Invalid shape, bounds, or geometry return `-1`.
- Output is six little-endian IEEE-754 binary64 values, ordered as circumcenter x/y, incenter x/y, and orthocenter x/y. Return 48 bytes. Insufficient output capacity returns `-2`.
- Float-vector comparisons use `1e-10` absolute and relative tolerance to cover differences between NumPy's determinant/linear-solve routines and the ports' equivalent scalar formulas.

The circumcenter uses the source's determinant equations, the incenter weights vertices by opposite-side lengths, and the orthocenter solves the two source altitude equations. The bounded integer input replaces Python `Point` construction and NumPy arrays while preserving the three center calculations.

[`workload.json`](workload.json) covers the documentation triangle, symmetric and scalene cases, invalid geometry, and output-capacity handling.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/triangle.c`](../../../c/t/triangle.c) |
| C3 | [`c3/t/triangle.c3`](../../../c3/t/triangle.c3) |
| C++ | [`cpp/t/triangle.cpp`](../../../cpp/t/triangle.cpp) |
| Elisa | [`elisa/t/triangle.elisa`](../../../elisa/t/triangle.elisa) |
| Nim | [`nim/t/triangle.nim`](../../../nim/t/triangle.nim) |
| Odin | [`odin/t/triangle.odin`](../../../odin/t/triangle.odin) |
| Rust | [`rust/t/triangle.rs`](../../../rust/t/triangle.rs) |
| V | [`v/t/triangle.v`](../../../v/t/triangle.v) |
| Zig | [`zig/t/triangle.zig`](../../../zig/t/triangle.zig) |
