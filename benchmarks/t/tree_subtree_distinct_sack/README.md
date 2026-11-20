# Tree subtree distinct colors with DSU on tree

For every vertex in a rooted tree, this benchmark returns the number of
different colors in its subtree. The root is vertex `0`. The primary method
precomputes subtree sizes and each vertex's largest child, processes that
heavy child's state while retaining it, then replays the light subtrees into
the shared color-frequency table. The answer is the number of colors whose
current frequency is nonzero.

## Contract

Input is `[n, parent[1..n-1], color[0..n-1]]`. Vertex labels are in preorder:
`0 <= parent[v] < v`, so these parent links form a rooted tree at zero. There
are 1 through 64 vertices and colors are integers in `0..255`. The input has
exactly `2*n` signed 64-bit words (up to 128 valid words; malformed frames up
to 130 words are parseable). Output is one little-endian signed 64-bit
subtree distinct-color count per vertex, in vertex-index order. The maximum
output is 512 bytes. Invalid or null input returns `-1`; null output or
capacity below `8*n` returns `-2`, without writing. The declared fixed
working-storage cap is 16384 bytes, separate from the caller-owned input and
512-byte maximum output.

## Algorithm and complexity

The parent array is expanded into child lists. A DFS order makes each subtree
contiguous; a reverse pass computes subtree sizes and selects a largest child.
The sack traversal discards each light child's temporary state, keeps the
heavy child's frequencies, adds all light-subtree vertices, and records the
distinct-color total. When a caller does not retain its state, its subtree is
removed from the frequency table. Each vertex is replayed or cleared only
across logarithmically many light edges, for `O(n log n)` work and `O(n + C)`
storage, where `C=256` is the color domain. The independently structured
reference instead flattens subtrees to intervals and answers all intervals by
a latest-occurrence Fenwick sweep. The primary oracle directly visits each
subtree and collects a set of colors.

This is a DSU-on-tree/sack workload, distinct from
[`offline_range_distinct_fenwick`](../offline_range_distinct_fenwick/README.md),
which sweeps arbitrary array intervals, and from
[`heavy_light_decomposition_metadata`](../../h/heavy_light_decomposition_metadata/README.md),
which reports decomposition metadata. The [OI Wiki DSU-on-tree article](https://oi-wiki.org/graph/dsu-on-tree/)
is used to identify the method. Its algorithmic idea is implemented
independently; no source code, prose, or fixtures are reused.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md),
[`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and the package-local
[`verify_workload.py`](verify_workload.py) static inventory/oracle check. Source
drafts are provided for all ten supported languages. Nothing has been compiled
or executed.

| Language | Draft |
|---|---|
| C | [C](../../../c/t/tree_subtree_distinct_sack.c) |
| C3 | [C3](../../../c3/t/tree_subtree_distinct_sack.c3) |
| C++ | [C++](../../../cpp/t/tree_subtree_distinct_sack.cpp) |
| Elisa | [Elisa](../../../elisa/t/tree_subtree_distinct_sack.elisa) |
| Mojo | [Mojo](../../../mojo/t/tree_subtree_distinct_sack.mojo) |
| Nim | [Nim](../../../nim/t/tree_subtree_distinct_sack.nim) |
| Odin | [Odin](../../../odin/t/tree_subtree_distinct_sack.odin) |
| Rust | [Rust](../../../rust/t/tree_subtree_distinct_sack.rs) |
| V | [V](../../../v/t/tree_subtree_distinct_sack.v) |
| Zig | [Zig](../../../zig/t/tree_subtree_distinct_sack.zig) |
