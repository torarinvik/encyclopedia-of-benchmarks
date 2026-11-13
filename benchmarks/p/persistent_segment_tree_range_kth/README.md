# Persistent segment tree range kth

This package benchmarks static range selection with persistent prefix
histograms. It is a clean-room implementation of the path-copying method
described by [CP-Algorithms, Segment Tree: finding the k-th smallest number in
a range](https://cp-algorithms.com/data_structures/segment_tree.html), whose
text is licensed CC BY-SA 4.0. Only the algorithm description was used; see
[`RIGHTS.md`](RIGHTS.md).

## Contract

- Scalar ABI symbol: `persistent_segment_tree_range_kth`.
- Input is `[N,Q,values[N],(L,R,K)*Q]`, all signed 64-bit words.
- `1<=N<=32`, `0<=Q<=32`, and values are in `[-1000,1000]`.
- Ranges are inclusive and zero-based. `1<=K<=R-L+1`; K is one-based.
- Return `sum((query_index+1)*answer)` across queries. With no queries the
  result is zero. Results lie in `[-528000,528000]`.
- Malformed framing or values return `INT64_MIN`.
- The maximum valid and parseable lengths are 130 and 131 words.
- Workspace is 4096 bytes. The ports use at most 193 persistent nodes: one
  null node plus at most six copied nodes for each of 32 insertions. Child
  indices and counts are 32-bit. The conservative cross-port fixed-storage
  budget is 2960 bytes (two 32-element i64 buffers, 33 i32 roots, and three
  193-element i32 node arrays); ports that read values directly from the ABI
  input use less.

The primary oracle coordinate-compresses values, path-copies a frequency
segment tree per prefix, and answers a range query by descending the difference
between roots `R+1` and `L`. The independent oracle sorts each queried slice.
The bounded workload includes repeated values, negative values, singleton and
zero-query cases, a maximum-size trace, and malformed inputs.

## Package artifacts

- Workload: [`workload.json`](workload.json)
- Primary oracle: [`primary_oracle.py`](primary_oracle.py)
- Independent oracle: [`independent_oracle.py`](independent_oracle.py)
- Static inventory checker: [`verify_persistent_segment_tree_range_kth_package.py`](../../verify_persistent_segment_tree_range_kth_package.py)

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/p/persistent_segment_tree_range_kth.c`](../../../c/p/persistent_segment_tree_range_kth.c) |
| C3 | [`c3/p/persistent_segment_tree_range_kth.c3`](../../../c3/p/persistent_segment_tree_range_kth.c3) |
| C++ | [`cpp/p/persistent_segment_tree_range_kth.cpp`](../../../cpp/p/persistent_segment_tree_range_kth.cpp) |
| Elisa | [`elisa/p/persistent_segment_tree_range_kth.elisa`](../../../elisa/p/persistent_segment_tree_range_kth.elisa) |
| Mojo | [`mojo/p/persistent_segment_tree_range_kth.mojo`](../../../mojo/p/persistent_segment_tree_range_kth.mojo) |
| Nim | [`nim/p/persistent_segment_tree_range_kth.nim`](../../../nim/p/persistent_segment_tree_range_kth.nim) |
| Odin | [`odin/p/persistent_segment_tree_range_kth.odin`](../../../odin/p/persistent_segment_tree_range_kth.odin) |
| Rust | [`rust/p/persistent_segment_tree_range_kth.rs`](../../../rust/p/persistent_segment_tree_range_kth.rs) |
| V | [`v/p/persistent_segment_tree_range_kth.v`](../../../v/p/persistent_segment_tree_range_kth.v) |
| Zig | [`zig/p/persistent_segment_tree_range_kth.zig`](../../../zig/p/persistent_segment_tree_range_kth.zig) |
