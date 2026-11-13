# Monotone convex hull trick

This profile answers minimum line queries with strictly decreasing slopes and
nondecreasing query coordinates. It builds a lower hull in a fixed array,
removing lines that never reach the envelope, then advances a front index as
queries increase. Each line and query is processed amortized O(1) times, for
O(L+Q) total time and O(L) auxiliary storage. The repository's
[`li_chao_tree`](../../l/li_chao_tree/README.md) supports arbitrary insertion order,
and [`range_linear_add_range_min`](../../r/range_linear_add_range_min/README.md)
uses block hulls and binary search; this package measures the monotone deque
variant.

The `i64_array_scalar` input is `[L,Q,(slope,intercept)*L,x[Q]]`. There are
1–32 lines and 0–32 queries. Slopes are strictly decreasing in `[-1000,1000]`,
intercepts are in `[-10000,10000]`, and query coordinates are nondecreasing in
`[-1000,1000]`. The return value is
`sum((i+1)*min_j(slope[j]*x[i]+intercept[j]))`, with one-based query index `i`.
Zero queries return zero. Malformed input returns `INT64_MIN`. The maximum
valid and parseable frames are 98 and 99 signed 64-bit values. A line value is
bounded by 1,010,000 and the absolute weighted checksum by 533,280,000, so the
cross products and checksum fit signed 64-bit arithmetic. The fixed line array
uses 512 bytes.

The primary oracle constructs and queries the same monotone lower hull. The
independent oracle scans every line for each query. The ports are clean-room
implementations based on the monotone-slope method described in
[CP-Algorithms' convex hull trick article](https://cp-algorithms.com/geometry/convex_hull_trick.html);
no source code or prose was copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`monotone_convex_hull_trick.c`](../../../c/m/monotone_convex_hull_trick.c) |
| C3 | [`monotone_convex_hull_trick.c3`](../../../c3/m/monotone_convex_hull_trick.c3) |
| C++ | [`monotone_convex_hull_trick.cpp`](../../../cpp/m/monotone_convex_hull_trick.cpp) |
| Elisa | [`monotone_convex_hull_trick.elisa`](../../../elisa/m/monotone_convex_hull_trick.elisa) |
| Mojo | [`monotone_convex_hull_trick.mojo`](../../../mojo/m/monotone_convex_hull_trick.mojo) |
| Nim | [`monotone_convex_hull_trick.nim`](../../../nim/m/monotone_convex_hull_trick.nim) |
| Odin | [`monotone_convex_hull_trick.odin`](../../../odin/m/monotone_convex_hull_trick.odin) |
| Rust | [`monotone_convex_hull_trick.rs`](../../../rust/m/monotone_convex_hull_trick.rs) |
| V | [`monotone_convex_hull_trick.v`](../../../v/m/monotone_convex_hull_trick.v) |
| Zig | [`monotone_convex_hull_trick.zig`](../../../zig/m/monotone_convex_hull_trick.zig) |

The workload and fixtures are in [`workload.json`](workload.json). Static source
inventory is documented by [`check_inventory.py`](check_inventory.py). The
primary and independent Python oracles are
[`monotone_convex_hull_trick_oracle.py`](../../monotone_convex_hull_trick_oracle.py)
and
[`monotone_convex_hull_trick_verifier_oracle.py`](../../monotone_convex_hull_trick_verifier_oracle.py).
