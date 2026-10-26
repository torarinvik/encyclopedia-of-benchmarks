# Non-shared edge distance for binary phylogenies

This profile computes the chapter's non-shared edge distance for two unrooted
binary phylogenies with the same labeled leaves. Each tree is represented by
its `2n-3` canonical edge splits: an integer mask names the side of the
bipartition that excludes leaf 0. A valid tree has all `n` pendant splits and
`n-3` compatible internal splits. The result is `2n-3` minus the number of
shared splits. This is the count of non-shared edges in either tree; it is
half the symmetric-difference form sometimes used for the Robinson–Foulds
metric.

Input is `[n, split_0..split_(2n-4) for tree A, split_0..split_(2n-4) for tree B]`,
with `3 <= n <= 8`. Each split mask is positive, uses only the low `n` bits,
and has bit 0 clear. Output is one little-endian signed 64-bit distance.
Invalid input returns `-1`; null output or capacity below 8 bytes returns
`-2` without writing. Maximum input length is 27 values and maximum output is
8 bytes. The split-set encoding is direct: it stores the leaf partitions that
define each edge in the source problem, rather than choosing internal vertex
names or an edge ordering.

The primary oracle compares canonical split masks. The independent verifier
converts them to leaf sets and validates the compatible hierarchy before
counting shared partitions. The bounded contract uses the chapter's exact
edge-partition definition; it does not implement the separate NNI or
subtree-transfer distances discussed in the chapter.

Primary oracle: [`non_shared_edges_oracle.py`](../../non_shared_edges_oracle.py).
Independent verifier: [`non_shared_edges_verifier_oracle.py`](../../non_shared_edges_verifier_oracle.py).

Source: “Non-shared Edges,” Wing-Kai Hon, *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_259`](https://doi.org/10.1007/978-1-4939-2864-4_259).
The chapter is used only to identify the problem and its edge-split semantics;
this is a clean-room implementation with no copied book text, figures, or
code.

## Workload and ports

The [workload](workload.json) covers the unique three-leaf tree, distinct
quartet topologies, reordered equal trees, the maximum eight-leaf tree,
malformed/incompatible split sets, null buffers, and insufficient capacity.

| Language | Port |
|---|---|
| C | `c/n/non_shared_edges.c` |
| C3 | `c3/n/non_shared_edges.c3` |
| C++ | `cpp/n/non_shared_edges.cpp` |
| Elisa | `elisa/n/non_shared_edges.elisa` |
| Nim | `nim/n/non_shared_edges.nim` |
| Odin | `odin/n/non_shared_edges.odin` |
| Rust | `rust/n/non_shared_edges.rs` |
| V | `v/n/non_shared_edges.v` |
| Zig | `zig/n/non_shared_edges.zig` |
