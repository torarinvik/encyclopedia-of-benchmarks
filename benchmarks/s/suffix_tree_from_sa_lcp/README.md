# Suffix tree from a suffix array and LCP array

This bounded profile covers the chapter's rightmost-path suffix-tree
construction from suffix-array order and adjacent longest-common-prefix (LCP)
values. The input is `[text_length, symbol...]`, with `0 <= text_length <= 8`
and symbols in `1..255`. The implementation appends a unique terminal symbol
`0`, constructs the suffix array and adjacent LCP values by direct comparison,
then applies the source's stack-based tree construction. The terminal-only
suffix is included.

The output is a canonical little-endian signed-i64 sequence. It begins with
`node_count`; each following five-word row is
`[parent_representative, parent_depth, node_representative, node_depth,
leaf_start]`. The root row is `[-1,-1,-1,0,-1]`. For every other node,
`representative` is the start of the lexicographically first suffix below that
node. A leaf's `leaf_start` equals its representative; an internal node has
`leaf_start = -1`. Depth counts symbols in the terminated text. Node rows are
sorted by `(node_depth, node_representative, leaf_start)`. Edge labels can be
recovered from the input text, terminal symbol, representatives, and depths.

The output captures the suffix-tree topology and split depths without
including allocator layout or disk-page state. The chapter analyzes
hierarchical-memory I/O complexity; this small in-memory profile does not
measure those external-memory bounds. It is distinct from the local
[`suffix_tree`](../suffix_tree/README.md) insertion profile, which inserts
suffixes in text order without a terminal marker and preserves its
implementation's node vector.

Malformed input returns `-1`. Null output or capacity below the complete
serialized result returns `-2` without writing. A valid input has at most nine
suffixes, seventeen nodes, and 688 output bytes. The largest accepted input
has nine values; a tenth value is parseable only to test trailing-data
rejection. Fixed workspace is bounded at 4096 bytes.

Primary oracle: [`suffix_tree_from_sa_lcp_oracle.py`](../../suffix_tree_from_sa_lcp_oracle.py).
Independent verifier: [`suffix_tree_from_sa_lcp_verifier_oracle.py`](../../suffix_tree_from_sa_lcp_verifier_oracle.py),
which builds a compressed trie recursively by prefix groups instead of using
the LCP stack recurrence.

Source: Paolo Ferragina, “Suffix Tree Construction in Hierarchical Memory,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_413`](https://doi.org/10.1007/978-1-4939-2864-4_413).
See [`RIGHTS.md`](RIGHTS.md) for attribution and provenance.

## Workload

The [workload](workload.json) covers empty text, repeated prefixes, the
maximum-node/output case, invalid alphabet values, malformed lengths, null
buffers, and insufficient capacity.

## Ports

| Language | Port |
| --- | --- |
| C | [`c/s/suffix_tree_from_sa_lcp.c`](../../../c/s/suffix_tree_from_sa_lcp.c) |
| C3 | [`c3/s/suffix_tree_from_sa_lcp.c3`](../../../c3/s/suffix_tree_from_sa_lcp.c3) |
| C++ | [`cpp/s/suffix_tree_from_sa_lcp.cpp`](../../../cpp/s/suffix_tree_from_sa_lcp.cpp) |
| Elisa | [`elisa/s/suffix_tree_from_sa_lcp.elisa`](../../../elisa/s/suffix_tree_from_sa_lcp.elisa) |
| Nim | [`nim/s/suffix_tree_from_sa_lcp.nim`](../../../nim/s/suffix_tree_from_sa_lcp.nim) |
| Odin | [`odin/s/suffix_tree_from_sa_lcp.odin`](../../../odin/s/suffix_tree_from_sa_lcp.odin) |
| Rust | [`rust/s/suffix_tree_from_sa_lcp.rs`](../../../rust/s/suffix_tree_from_sa_lcp.rs) |
| V | [`v/s/suffix_tree_from_sa_lcp.v`](../../../v/s/suffix_tree_from_sa_lcp.v) |
| Zig | [`zig/s/suffix_tree_from_sa_lcp.zig`](../../../zig/s/suffix_tree_from_sa_lcp.zig) |
