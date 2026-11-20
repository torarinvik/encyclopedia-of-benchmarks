# Cohen–Sutherland line clipping

This bounded profile clips one directed line segment to an axis-aligned
rectangle using Cohen–Sutherland endpoint region codes. It is method-distinct
from the local [Liang–Barsky clipper](../../l/liang_barsky/README.md):
Cohen–Sutherland repeatedly replaces an outside endpoint after testing its
four-bit outcode, while Liang–Barsky intersects a scalar parameter interval
with four half-space constraints.

## Contract

The exported symbol is `cohen_sutherland` in the `i64_array_float64` ABI
family. Input is exactly
`[component,xmin_micro,ymin_micro,xmax_micro,ymax_micro,x1_micro,y1_micro,x2_micro,y2_micro]`.
All eight coordinate values are signed integer millionths in
`[-1,000,000,000,1,000,000,000]`, corresponding to real coordinates in
`[-1000,1000]`. The rectangle must have positive width and height. The
component selector is 0 through 4.

Coordinates are converted to binary64 by division by one million. A point on a
rectangle edge is inside. The outcode bits are left=1, right=2, below=4, and
above=8. Each iteration accepts when both codes are zero, rejects when their
bitwise intersection is nonzero, or clips the first outside endpoint against
one boundary. The source-compatible boundary priority is top, bottom, right,
then left. The newly computed endpoint replaces that endpoint and receives a
fresh outcode. At most four boundary intersections are needed: every
replacement clears at least one of the two endpoint's outcode bits.

Selectors 0–3 return the clipped first x, first y, second x, or second y,
respectively. If the segment is rejected, these coordinate selectors return
`-1e300`. Selector 4 returns `1.0` for an accepted segment and `0.0` for a
rejected segment. Invalid framing, selector, coordinates, or rectangle returns
`-1e300`. A zero-length segment inside or on the rectangle is accepted and
retains its input coordinate. The result is compared with absolute tolerance
`1e-9` and relative tolerance `1e-12`.

The primary [oracle](../../cohen_sutherland_oracle.py) follows the
region-code iteration. The independent
[reference](independent_oracle.py) uses Liang–Barsky's entering/leaving
parameter interval and evaluates the clipped endpoints from the original
segment. The independent formulation does not share outcodes, repeated
endpoint replacement, or boundary-priority control flow.

## Bounds and workload

The valid input contains 9 signed 64-bit words; the workload also includes an
extra-word rejection frame. The algorithm uses constant auxiliary storage.
The scalar result is one binary64 value. [`workload.json`](workload.json)
contains pinned expected values for full crossings, inside and rejected
segments, vertical and horizontal lines, a corner crossing, a degenerate
point, and invalid input. [`verify_workload.py`](verify_workload.py) is a
metadata/reference agreement helper; [`check_inventory.py`](check_inventory.py)
checks only package files and metadata. See the static package summary in
[`INVENTORY.md`](INVENTORY.md) and machine-readable
[`INVENTORY.json`](INVENTORY.json).

## Sources and provenance

The algorithm description is cross-checked against McGill University's
[computer graphics clipping notes](https://cim.mcgill.ca/~langer/557/6-slides-9pp.pdf)
and the University of Helsinki's [Cohen–Sutherland overview](https://www.cs.helsinki.fi/group/goa/viewing/leikkaus/uuu).
The pinned [TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/CohenSutherland.java)
identifies the source-specific tie order retained by this profile. Only the
algorithm and behavior were used; no source code, tests, examples, or task text
were copied. See [RIGHTS.md](RIGHTS.md) for the upstream license and reuse
record.

## Native ports

| Language | Source |
|---|---|
| C | [`c/c/cohen_sutherland.c`](../../../c/c/cohen_sutherland.c) |
| C3 | [`c3/c/cohen_sutherland.c3`](../../../c3/c/cohen_sutherland.c3) |
| C++ | [`cpp/c/cohen_sutherland.cpp`](../../../cpp/c/cohen_sutherland.cpp) |
| Elisa | [`elisa/c/cohen_sutherland.elisa`](../../../elisa/c/cohen_sutherland.elisa) |
| Mojo | [`mojo/c/cohen_sutherland.mojo`](../../../mojo/c/cohen_sutherland.mojo) |
| Nim | [`nim/c/cohen_sutherland.nim`](../../../nim/c/cohen_sutherland.nim) |
| Odin | [`odin/c/cohen_sutherland.odin`](../../../odin/c/cohen_sutherland.odin) |
| Rust | [`rust/c/cohen_sutherland.rs`](../../../rust/c/cohen_sutherland.rs) |
| V | [`v/c/cohen_sutherland.v`](../../../v/c/cohen_sutherland.v) |
| Zig | [`zig/c/cohen_sutherland.zig`](../../../zig/c/cohen_sutherland.zig) |

This package and its ports have received source-only review. No programs,
tests, checkers, builds, compilers, profilers, or benchmarks have been run for
this completion pass.
