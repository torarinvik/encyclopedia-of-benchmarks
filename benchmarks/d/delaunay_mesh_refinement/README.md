# One-step Delaunay mesh refinement

This bounded profile applies the quality-driven circumcenter insertion used by the pinned DTCC Mesher refinement loop. It starts from one acute counter-clockwise triangle and performs at most one refinement step. The fixed quality target is 20 degrees; a triangle is bad when its circumradius-to-shortest-edge ratio exceeds `1 / (2 sin(20°))`, using the source's `1e-12` comparison margin. A bad seed is split at its circumcenter into three counter-clockwise triangles. An already good seed is returned unchanged.

The acute-triangle precondition makes the circumcenter strictly interior, so this profile exercises the source's unencumbered circumcenter insertion path. It intentionally bounds one loop step; it does not claim convergence or implement constrained-segment splitting and acute-corner protection.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `delaunay_mesh_refinement`.
- Input is `[3, x0, y0, x1, y1, x2, y2]`. Coordinates are integers in `[-100,100]`; vertices must be distinct, strictly counter-clockwise, non-collinear, and form an acute triangle. Invalid input returns `-1`.
- Output is little-endian signed 64-bit words: `[vertex_count, x0_micro, y0_micro, ..., triangle_count, a0, b0, c0, ...]`. Coordinates are millionths, rounded to nearest with ties away from zero. The original seed triangle is `(0,1,2)`; after insertion the fan is `(0,1,3), (1,2,3), (2,0,3)`.
- Output length is 88 bytes for an unchanged seed and 152 bytes after insertion. Null or short output returns `-2` without writes. Workspace is 152 bytes.

## Source and license

The algorithm is based on `src/core/cdt.c` in [`dtcc-platform/dtcc-mesher`](https://github.com/dtcc-platform/dtcc-mesher/blob/0bba17bbd0d5de4b3a65b0451c4e5db303e541ac/src/core/cdt.c), pinned at commit `0bba17bbd0d5de4b3a65b0451c4e5db303e541ac`. The source uses the radius-edge quality bound, computes the bad triangle's circumcenter, checks encroached constraints, and inserts the point when the unconstrained branch applies. This package ports that bounded branch and includes the project's MIT notice in [`LICENSE.md`](LICENSE.md).

## Oracle and ports

The independent oracle is [`delaunay_mesh_refinement_oracle.py`](../../delaunay_mesh_refinement_oracle.py). Each language implementation follows the same input, quantization, output order, and error contract.
