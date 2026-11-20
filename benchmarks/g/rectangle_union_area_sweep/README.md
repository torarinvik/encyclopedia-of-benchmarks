# General Rectangle Union Area Sweep

This profile computes the total area covered by a bounded set of axis-aligned
rectangles. It sweeps a vertical line across sorted x-events. Between adjacent
x coordinates, it adds the strip width times the currently covered y-length.
A compressed-coordinate segment tree maintains that y-length; each rectangle
adds its y-interval at its left edge and removes it at its right edge. At a
shared x-coordinate, starts are applied before removals so intermediate cover
counts remain nonnegative.

This is Bentley's two-dimensional Klee-measure algorithm. The general set
profile is distinct from local [`rectangle_union_area`](../../r/rectangle_union_area/README.md),
which evaluates the constant-time formula for exactly two rectangles. It also
differs from [`triangle_union_area_vertical_decomposition`](../../t/triangle_union_area_vertical_decomposition/README.md),
which constructs an exact vertical decomposition for triangles.

## Contract

The `i64_array_scalar` input is `[n, x1, y1, x2, y2, ...]`, with exactly
`1 + 4*n` signed 64-bit words and `0 <= n <= 64`. Each rectangle is
`[x1,y1,x2,y2]` with `-1,000,000,000 <= x1,y1,x2,y2 <= 1,000,000,000`,
`x1 < x2`, and `y1 < y2`. Empty input set `[0]` returns area zero. Null,
malformed, degenerate, or out-of-range inputs return `-1`; the input is read
only. The maximum valid frame is 257 words and the parse limit is 258 words.
The union area is at most `4,000,000,000,000,000,000`, which fits signed
64-bit arithmetic.

All ports use fixed-capacity storage for at most 128 x-events, 128 y
coordinates, and a 512-node coverage tree. These arrays use 13,312 bytes. The
Mojo port uses an additional bounded stack of 32 four-field traversal frames,
so the package maximum fixed-array workspace is 13,824 bytes. The sweep and
segment-tree updates take `O(n log n)` time and `O(n)` workspace.

The primary reference sweeps x-slabs and merges active y-intervals directly.
The independent small-grid reference marks covered unit cells. The custom
workload checker compares both references on small-coordinate fixtures; the
large-coordinate fixtures use the interval-merge reference.

## Provenance

The algorithm is Bentley's plane sweep for Klee's rectangle-measure problem.
Bentley's original 1977 notes are unpublished. Van Leeuwen and Wood describe
the sweep and Bentley's covering segment tree in their 1979 technical report
and 1981 *Journal of Algorithms* paper. The implementation follows those
algorithm descriptions; no external code or prose is copied. See
[`RIGHTS.md`](RIGHTS.md), [`INVENTORY.md`](INVENTORY.md), and
[`workload.json`](workload.json).

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/g/rectangle_union_area_sweep.c`](../../../c/g/rectangle_union_area_sweep.c) |
| C3 | [`c3/g/rectangle_union_area_sweep.c3`](../../../c3/g/rectangle_union_area_sweep.c3) |
| C++ | [`cpp/g/rectangle_union_area_sweep.cpp`](../../../cpp/g/rectangle_union_area_sweep.cpp) |
| Elisa | [`elisa/g/rectangle_union_area_sweep.elisa`](../../../elisa/g/rectangle_union_area_sweep.elisa) |
| Mojo | [`mojo/g/rectangle_union_area_sweep.mojo`](../../../mojo/g/rectangle_union_area_sweep.mojo) |
| Nim | [`nim/g/rectangle_union_area_sweep.nim`](../../../nim/g/rectangle_union_area_sweep.nim) |
| Odin | [`odin/g/rectangle_union_area_sweep.odin`](../../../odin/g/rectangle_union_area_sweep.odin) |
| Rust | [`rust/g/rectangle_union_area_sweep.rs`](../../../rust/g/rectangle_union_area_sweep.rs) |
| V | [`v/g/rectangle_union_area_sweep.v`](../../../v/g/rectangle_union_area_sweep.v) |
| Zig | [`zig/g/rectangle_union_area_sweep.zig`](../../../zig/g/rectangle_union_area_sweep.zig) |

The ten language ports are registered in the shared `i64_array_scalar`
runner and verifier.

Sources: Bentley's 1977 *Solutions to Klee's Rectangle Problems* (unpublished
notes, Carnegie Mellon University), and van Leeuwen and Wood, [*The Measure
Problem for Rectangular Ranges in d-Space*](https://doi.org/10.1016/0196-6774(81)90027-4).
An accessible author technical report is [RUU-CS-79-6](https://ics-archive.science.uu.nl/research/techreps/repo/CS-1979/1979-06.pdf).
