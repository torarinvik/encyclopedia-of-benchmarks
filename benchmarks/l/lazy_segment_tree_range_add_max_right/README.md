# Lazy segment-tree range addition and `max_right`

This benchmark combines lazy range addition with a sum-monoid `max_right`
boundary search. It follows the published AtCoder Library lazy segment-tree
semantics. The bounded ports use a nonnegative-sum predicate, so once a prefix
exceeds its limit, every longer prefix also fails.

## Contract

The ABI is `i64_array_scalar`; the exported symbol and package id are
`lazy_segment_tree_range_add_max_right`. Input is
`[n,q,initial_values[n],(opcode,left,right,x)*q]`, with exact length
`2+n+4*q`:

- `1<=n<=16`, `0<=q<=12`, and every initial value is in `0..31`.
- `[0,left,right,delta]` adds `delta` in `0..31` to the half-open range
  `[left,right)`, where `0<=left<=right<=n`.
- `[1,left,limit,0]` returns the greatest endpoint `e` in `[left,n]` such
  that the sum of `[left,e)` is at most `limit`, where `0<=left<=n` and
  `0<=limit<=8192`. The final field is reserved and must be zero.
- The scalar packs each query endpoint in a five-bit field, in query order.
  Updates emit no field. At most twelve fields use at most 60 bits.
- Null or malformed input returns `-1`.

All values and additions are nonnegative. After at most twelve updates, each
element is at most 403 and the full sum is at most 6,448. The limit bound
covers every possible sum. The valid frame is at most 66 words; the parser
accepts up to 67 words before exact-length validation.

## Algorithm and distinction

The tree stores segment sums and a pending addition per node. A covered range
is updated in one step. During `max_right`, the search consumes whole nodes
while the accumulated sum remains within the limit. If a node would cross the
limit, it pushes any pending addition before descending to its children. This
keeps updates and searches at `O(log n)` each.

[`segment_tree_max_right`](../../s/segment_tree_max_right/README.md) combines
point assignment with boundary search but has no lazy updates.
[`lazy_segment_tree_range_add_sum`](../lazy_segment_tree_range_add_sum/README.md)
and [`range_affine_range_sum`](../../r/range_affine_range_sum/README.md)
combine lazy updates with range aggregates but do not search for a boundary.
The workload includes a full-range pending tag followed by a search that must
push it while descending, so both parts of this combined procedure are
exercised.

The primary oracle uses a lazy sum tree and tree-guided descent. The independent
oracle replays additions in a flat array and scans each queried suffix.
[`workload.json`](workload.json) contains the hand-reviewed fixtures.

## Source and rights

The semantics follow the official
[AtCoder Library lazy segment-tree documentation](https://atcoder.github.io/ac-library/production/document_en/lazysegtree.html)
and [`lazysegtree.hpp`](https://github.com/atcoder/ac-library/blob/master/atcoder/lazysegtree.hpp).
AtCoder Library is released under CC0 1.0 Universal. The ports, workload, and
oracles are clean-room implementations of the published algorithm semantics;
no library code, prose, tests, or fixtures were copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/lazy_segment_tree_range_add_max_right.c`](../../../c/l/lazy_segment_tree_range_add_max_right.c) |
| C3 | [`c3/l/lazy_segment_tree_range_add_max_right.c3`](../../../c3/l/lazy_segment_tree_range_add_max_right.c3) |
| C++ | [`cpp/l/lazy_segment_tree_range_add_max_right.cpp`](../../../cpp/l/lazy_segment_tree_range_add_max_right.cpp) |
| Elisa | [`elisa/l/lazy_segment_tree_range_add_max_right.elisa`](../../../elisa/l/lazy_segment_tree_range_add_max_right.elisa) |
| Mojo | [`mojo/l/lazy_segment_tree_range_add_max_right.mojo`](../../../mojo/l/lazy_segment_tree_range_add_max_right.mojo) |
| Nim | [`nim/l/lazy_segment_tree_range_add_max_right.nim`](../../../nim/l/lazy_segment_tree_range_add_max_right.nim) |
| Odin | [`odin/l/lazy_segment_tree_range_add_max_right.odin`](../../../odin/l/lazy_segment_tree_range_add_max_right.odin) |
| Rust | [`rust/l/lazy_segment_tree_range_add_max_right.rs`](../../../rust/l/lazy_segment_tree_range_add_max_right.rs) |
| V | [`v/l/lazy_segment_tree_range_add_max_right.v`](../../../v/l/lazy_segment_tree_range_add_max_right.v) |
| Zig | [`zig/l/lazy_segment_tree_range_add_max_right.zig`](../../../zig/l/lazy_segment_tree_range_add_max_right.zig) |
