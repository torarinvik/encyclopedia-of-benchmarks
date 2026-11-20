# Intersecting segments endpoint sweep

This package returns whether any pair of bounded planar segments intersects.
The primary procedure follows the endpoint-sweep method described by
CP-Algorithms: sort segment endpoint events by x, maintain the currently active
segments in vertical order, and test only new adjacent pairs. When a segment
ends, remove it and test the pair that becomes adjacent in its place. The
independent reference checks every unordered segment pair directly.

## Contract

The exported symbol is `intersecting_segments_sweep`, with ABI
`i64_array_scalar`. Input is `[n,(x1,y1,x2,y2)*n]`.

- `0 <= n <= 24`; coordinates are signed integers in `[-100,100]`.
- Every segment is nonvertical and normalized so `x1 < x2`.
- All `2n` endpoint x coordinates are distinct. This keeps event order
  unambiguous and lets each event be represented by one x value and one
  segment ID.
- Segment intersection is inclusive: proper crossings, an endpoint lying on
  another segment, and collinear overlap all count.
- Return `1` if any pair intersects, `0` if none do, and `-1` for null or
  malformed input. The maximum valid frame is 97 signed 64-bit words; a
  one-word trailing frame of length 98 is rejected.

## Active-set representation and complexity

The ports use a compact array of active segment IDs, ordered by exact rational
height at the current endpoint x. Height comparisons cross-multiply bounded
integer numerators and positive x spans; slope and ID break exact-height ties.
The slope and ID fields only make the insertion order deterministic. At a
start event, equal-height active segments and the entering segment meet at that
x, form one contiguous block in height order, and the entering segment is
checked against an adjacent member of that block. At an end event there is
only one event at that x because endpoint x values are unique. The departing
segment has remained in the status through every intervening endpoint event,
where insertion and removal adjacency checks apply. After its removal the
sweep checks the newly adjacent remaining pair. Thus an end-event tie does not
require reordering the active array. For the existential result, the sweep's
adjacency invariant is that disjoint active segments cannot change vertical
order: an order change requires an intersection. If an intersecting pair is
separated in the status by other active segments, one of the intervening pairs
must meet no later; the earliest such meeting is exposed by an insertion or a
new adjacency after removal. If several segments meet at once, they form a
contiguous equal-height block and an adjacent pair suffices for this
existential result. The ports use inclusive orientation and bounding checks,
so a tie at a shared endpoint or a collinear overlap counts as intersection.
Insertion finds the position with a linear scan, and insertion/removal shifts
the array. Thus this bounded implementation takes `O(n^2)` time in the worst
case and `O(n)` workspace. The sweep performs at most a constant number of
intersection tests per event (at most `3n`); the quadratic bound comes from
event sorting and array-backed active-list positioning and shifts. A balanced
status tree could reduce those costs, but would add implementation-specific
ordering risk across the language ports.

The primary Python reference models the same sweep and exact status ordering.
The structurally independent reference uses orientation tests and checks all
pairs, without events or an active set. The workload covers disjoint segments,
proper crossings, endpoint-on-segment contact, collinear overlap, a maximum
size instance, malformed frames, and null input.

Source: [CP-Algorithms, “Search for a pair of intersecting segments”](https://cp-algorithms.com/geometry/intersecting_segments.html).
Only the algorithm description was used; all ports and benchmark data are
clean-room work.

| Language | Source |
|---|---|
| C | [`c/i/intersecting_segments_sweep.c`](../../../c/i/intersecting_segments_sweep.c) |
| C3 | [`c3/i/intersecting_segments_sweep.c3`](../../../c3/i/intersecting_segments_sweep.c3) |
| C++ | [`cpp/i/intersecting_segments_sweep.cpp`](../../../cpp/i/intersecting_segments_sweep.cpp) |
| Elisa | [`elisa/i/intersecting_segments_sweep.elisa`](../../../elisa/i/intersecting_segments_sweep.elisa) |
| Mojo | [`mojo/i/intersecting_segments_sweep.mojo`](../../../mojo/i/intersecting_segments_sweep.mojo) |
| Nim | [`nim/i/intersecting_segments_sweep.nim`](../../../nim/i/intersecting_segments_sweep.nim) |
| Odin | [`odin/i/intersecting_segments_sweep.odin`](../../../odin/i/intersecting_segments_sweep.odin) |
| Rust | [`rust/i/intersecting_segments_sweep.rs`](../../../rust/i/intersecting_segments_sweep.rs) |
| V | [`v/i/intersecting_segments_sweep.v`](../../../v/i/intersecting_segments_sweep.v) |
| Zig | [`zig/i/intersecting_segments_sweep.zig`](../../../zig/i/intersecting_segments_sweep.zig) |
