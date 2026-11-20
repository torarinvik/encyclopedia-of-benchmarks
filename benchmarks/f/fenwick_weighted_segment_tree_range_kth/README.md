# Fenwick tree of weighted value trees: dynamic range k-th

This package supports replacing one array value and selecting the k-th value in
an arbitrary half-open range. The primary algorithm stores a mutable weighted
value segment tree at every node of an outer Fenwick tree. For a range query,
the two Fenwick prefix decompositions are descended together; their left-child
counts determine which half contains the requested rank.

## Contract

The exported scalar ABI is `i64_array_scalar`, symbol
`fenwick_weighted_segment_tree_range_kth`. Input is
`[n, q, initial[n], operation_rows...]`. Each operation row has four signed
64-bit integers:

- Update: `[0, position, new_value, 0]`, using a zero-based position.
- Range k-th query: `[1, left, right, k]`, over `[left,right)` with one-based
  rank `k`.
- `1 <= n <= 12`, `0 <= q <= 16`, and initial and replacement values are in
  `[-30,30]`. Queries require `0 <= left < right <= n` and
  `1 <= k <= right-left`.
- Any malformed frame or operation returns `INT64_MIN`. The exact input length
  is `2+n+4*q`; maximum valid and parseable lengths are 78 and 79 words.
- If query answers in order are `a_1,...,a_m`, the result is
  `sum(j*a_j)` for one-based query ordinal `j`. An operation stream without
  queries returns zero. The result range is `[-4080,4080]`.

The primary method uses a Fenwick tree over positions, with a dynamically
updated value-frequency segment tree in each Fenwick node. Each point
replacement and range selection takes `O(log n log V)` time, where
`V=61` possible values. Storage is bounded by 1,280 value-tree nodes for this
input profile. The independent reference replays replacements in a flat array
and sorts each queried slice.

This is distinct from
[`persistent_segment_tree_range_kth`](../../p/persistent_segment_tree_range_kth/README.md),
which answers static range selections from path-copied prefix roots and does
not support replacements. This profile specifically measures the mutable
Fenwick-of-weighted-value-trees method described by
[OI Wiki](https://www.timothywang.ca/OI-wiki/ds/seg-in-bit/). The implementation
is a clean-room translation of the algorithmic method; details are recorded in
[`RIGHTS.md`](RIGHTS.md).

## Package artifacts

The bounded contract and manually derived fixtures are in
[`workload.json`](workload.json). The two Python references and the static
artifact/source checker are listed in [`INVENTORY.md`](INVENTORY.md). Shared
suite wiring is maintained separately.

| Language | Source |
|---|---|
| C | [`c/f/fenwick_weighted_segment_tree_range_kth.c`](../../../c/f/fenwick_weighted_segment_tree_range_kth.c) |
| C3 | [`c3/f/fenwick_weighted_segment_tree_range_kth.c3`](../../../c3/f/fenwick_weighted_segment_tree_range_kth.c3) |
| C++ | [`cpp/f/fenwick_weighted_segment_tree_range_kth.cpp`](../../../cpp/f/fenwick_weighted_segment_tree_range_kth.cpp) |
| Elisa | [`elisa/f/fenwick_weighted_segment_tree_range_kth.elisa`](../../../elisa/fenwick_weighted_segment_tree_range_kth.elisa) |
| Mojo | [`mojo/f/fenwick_weighted_segment_tree_range_kth.mojo`](../../../mojo/f/fenwick_weighted_segment_tree_range_kth.mojo) |
| Nim | [`nim/f/fenwick_weighted_segment_tree_range_kth.nim`](../../../nim/f/fenwick_weighted_segment_tree_range_kth.nim) |
| Odin | [`odin/f/fenwick_weighted_segment_tree_range_kth.odin`](../../../odin/f/fenwick_weighted_segment_tree_range_kth.odin) |
| Rust | [`rust/f/fenwick_weighted_segment_tree_range_kth.rs`](../../../rust/f/fenwick_weighted_segment_tree_range_kth.rs) |
| V | [`v/f/fenwick_weighted_segment_tree_range_kth.v`](../../../v/f/fenwick_weighted_segment_tree_range_kth.v) |
| Zig | [`zig/f/fenwick_weighted_segment_tree_range_kth.zig`](../../../zig/fenwick_weighted_segment_tree_range_kth.zig) |

All language ports are source drafts; no programs or verification tools have
been run.
