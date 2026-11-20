# Segment-tree max_right boundary search

This package combines point assignments with a segment-tree search for the
largest prefix endpoint whose sum stays within a nonnegative limit. It follows
the `max_right` semantics documented by AtCoder Library and rebuilds the tree
for each call.

## Contract

The ABI is `i64_array_scalar`; the exported symbol and package id are
`segment_tree_max_right`. Input is `[n, operation_count, initial_values...,
operation_rows...]`, where each row is three integers:

- `[0, index, value]` assigns a value at `index`.
- `[1, left, limit]` asks for the maximum `right` such that
  `sum(values[left:right]) <= limit`.

`0<=n<=16`, `0<=operation_count<=12`, and the exact frame length is
`2+n+3*operation_count`. Values and assigned values are in `0..1000`; query
starts are in `0..n`, and limits are in `0..16000`. Nonnegative values make the
sum predicate monotone and guarantee `f(identity)=true`. Invalid or null input
returns `-1`.

The scalar result packs query endpoints in five-bit fields, in query order.
Each endpoint is in `0..16`, and there are at most twelve queries, so the
result fits in 60 bits. Updates do not emit result fields.

## Algorithm and distinction

The tree stores sums for a monoid. A `max_right` query consumes whole tree
segments while their accumulated sum remains within the limit, then descends
the first segment that would violate the predicate. This gives `O(log n)`
searches with `O(log n)` point updates. The existing ordinary segment-tree
benchmark covers point updates and interval aggregates; this package measures
tree-guided boundary search, which static prefix scans and ordinary range
queries do not provide.

The primary oracle repeats the segment-tree search. The independent oracle
scans the current array directly after each update.

## Source and ports

The API semantics and complexity follow the official
[AtCoder Library segtree documentation](https://atcoder.github.io/ac-library/master/document_en/segtree.html)
and the [AtCoder Library repository](https://github.com/atcoder/ac-library).
Only the published algorithm description is used; no library code is copied.
See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/s/segment_tree_max_right.c`](../../../c/s/segment_tree_max_right.c) |
| C3 | [`c3/s/segment_tree_max_right.c3`](../../../c3/s/segment_tree_max_right.c3) |
| C++ | [`cpp/s/segment_tree_max_right.cpp`](../../../cpp/s/segment_tree_max_right.cpp) |
| Elisa | [`elisa/s/segment_tree_max_right.elisa`](../../../elisa/s/segment_tree_max_right.elisa) |
| Mojo | [`mojo/s/segment_tree_max_right.mojo`](../../../mojo/s/segment_tree_max_right.mojo) |
| Nim | [`nim/s/segment_tree_max_right.nim`](../../../nim/s/segment_tree_max_right.nim) |
| Odin | [`odin/s/segment_tree_max_right.odin`](../../../odin/s/segment_tree_max_right.odin) |
| Rust | [`rust/s/segment_tree_max_right.rs`](../../../rust/s/segment_tree_max_right.rs) |
| V | [`v/s/segment_tree_max_right.v`](../../../v/s/segment_tree_max_right.v) |
| Zig | [`zig/s/segment_tree_max_right.zig`](../../../zig/s/segment_tree_max_right.zig) |

[`workload.json`](workload.json) includes updates, zero-valued runs, empty
arrays, maximum framing, and invalid frames. [`verify_workload.py`](verify_workload.py)
provides a static fixture and source inventory review.
