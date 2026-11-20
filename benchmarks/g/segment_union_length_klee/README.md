# Klee's segment-union sweep

This package measures the union of bounded one-dimensional intervals. It
sorts tagged endpoint events, maintains the number of open intervals, and adds
the gap between adjacent endpoint coordinates whenever that count is positive.
Events sharing a coordinate are grouped before the next gap is processed, so
coincident and touching intervals need no special-case logic.

## Contract

The `i64_array_scalar` input is `[n,(left,right)*n]`, where `0<=n<=64` and
`-1000<=left<=right<=1000`. The result is the continuous measure of the union,
in the range 0 through 2000. An empty collection and collections containing
only zero-length intervals return 0. Malformed or out-of-profile input returns
`-1`.

The primary uses a sorted endpoint-event sweep in `O(n log n)` time and `O(n)`
workspace. The independent oracle sorts unique coordinates, then scans every
interval for each adjacent coordinate slab. That slab scan has a different
kernel from the active-event count.

## Provenance and inventory

The method idea comes from CP-Algorithms' [Length of the union of segments](https://cp-algorithms.com/geometry/length-of-segments-union.html), published
under CC BY-SA 4.0. The implementations, bounded contract, references, and
fixtures are clean-room work based on the algorithm description. See
[`RIGHTS.md`](RIGHTS.md). The maximum frame contains 64 disjoint unit intervals
over `[0,127]`, so its union measure is 64. The source-only
[`verify_workload.py`](verify_workload.py) checks package metadata, fixtures,
references, and the ten exported source symbols without compiling or running
the ports.

| Language | Source |
|---|---|
| C | [`c/g/segment_union_length_klee.c`](../../../c/g/segment_union_length_klee.c) |
| C3 | [`c3/g/segment_union_length_klee.c3`](../../../c3/g/segment_union_length_klee.c3) |
| C++ | [`cpp/g/segment_union_length_klee.cpp`](../../../cpp/g/segment_union_length_klee.cpp) |
| Elisa | [`elisa/g/segment_union_length_klee.elisa`](../../../elisa/g/segment_union_length_klee.elisa) |
| Mojo | [`mojo/g/segment_union_length_klee.mojo`](../../../mojo/g/segment_union_length_klee.mojo) |
| Nim | [`nim/g/segment_union_length_klee.nim`](../../../nim/g/segment_union_length_klee.nim) |
| Odin | [`odin/g/segment_union_length_klee.odin`](../../../odin/g/segment_union_length_klee.odin) |
| Rust | [`rust/g/segment_union_length_klee.rs`](../../../rust/g/segment_union_length_klee.rs) |
| V | [`v/g/segment_union_length_klee.v`](../../../v/g/segment_union_length_klee.v) |
| Zig | [`zig/g/segment_union_length_klee.zig`](../../../zig/g/segment_union_length_klee.zig) |
