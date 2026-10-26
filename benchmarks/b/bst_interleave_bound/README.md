# Binary-search-tree interleave lower bound

This profile computes the interleave bound defined in the chapter. The static
BST contains keys `0..n-1`, named by their key ranks, and is supplied as a root
index and `(left_child, right_child)` pair for every key. A query sequence
contains key ranks in the same range. The input tree must be a connected BST
over exactly those keys.

For each pivot key `y`, consider only accesses in `y`'s subtree. Label an
access left when its key is at most `y` (the pivot belongs to its own left
side) and right when its key is greater than `y`. Count label changes in this
filtered sequence; the output is the sum over all pivots. This is Wilber's
interleave lower bound, not the Tango search structure itself.

Input is `[n, root, (left,right)..., access_count, access_keys...]`, with
`1 <= n <= 8` and at most 16 accesses. Output is one little-endian signed i64.
Malformed trees, keys, or framing return `-1`; null output or capacity below
8 bytes returns `-2` without writing. Maximum valid input is 35 values and
maximum parseable length is 36.

The primary oracle computes each subtree's key mask and filters the access
sequence. The independent verifier tests subtree membership by walking parent
links from each accessed key. This is distinct from local BST insertion,
search, and range-sum profiles.

Source: Chengwen Chris Wang and Daniel Sleator, “O(log log n)-Competitive
Binary Search Tree,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_263`](https://doi.org/10.1007/978-1-4939-2864-4_263).
The chapter states the Tango-tree competitiveness result but omits its
construction details; this package covers the separately defined interleave
bound only. See [`RIGHTS.md`](RIGHTS.md) for attribution.

## Workload and ports

The [workload](workload.json) includes alternating accesses, an empty access
sequence, the maximum tree/sequence, invalid BST order, malformed lengths,
null buffers, and insufficient capacity.

| Language | Port |
| --- | --- |
| C | [`c/b/bst_interleave_bound.c`](../../../c/b/bst_interleave_bound.c) |
| C3 | [`c3/b/bst_interleave_bound.c3`](../../../c3/b/bst_interleave_bound.c3) |
| C++ | [`cpp/b/bst_interleave_bound.cpp`](../../../cpp/b/bst_interleave_bound.cpp) |
| Elisa | [`elisa/b/bst_interleave_bound.elisa`](../../../elisa/b/bst_interleave_bound.elisa) |
| Nim | [`nim/b/bst_interleave_bound.nim`](../../../nim/b/bst_interleave_bound.nim) |
| Odin | [`odin/b/bst_interleave_bound.odin`](../../../odin/b/bst_interleave_bound.odin) |
| Rust | [`rust/b/bst_interleave_bound.rs`](../../../rust/b/bst_interleave_bound.rs) |
| V | [`v/b/bst_interleave_bound.v`](../../../v/b/bst_interleave_bound.v) |
| Zig | [`zig/b/bst_interleave_bound.zig`](../../../zig/b/bst_interleave_bound.zig) |
