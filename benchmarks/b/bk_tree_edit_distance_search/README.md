# BK-tree Levenshtein Radius Search

This package builds a static Burkhard–Keller metric tree from a bounded word
dictionary, then searches it for every dictionary word within a supplied
Levenshtein radius of each query. A node is a dictionary word; its child edge
is labelled with the edit distance from that node's word to the child's word.
For a query at distance `d` from a node and radius `r`, the search visits only
children whose edge labels lie in `[max(0,d-r), min(10,d+r)]`. The interval
follows from the triangle inequality.

The tree is built in dictionary order. Each word is inserted by following the
edge labelled with its distance to the current pivot, creating a child when
that edge is absent. Dictionary words must be distinct, so a zero-distance
edge is never needed. Queries visit eligible edge labels in increasing order;
this pins traversal without changing the set of matches.

## Contract

The `i64_array_scalar` input is `[n,q,r,word_0,...,word_(n-1),query_0,...]`.
There are exactly `3+n+q` words, with `0<=n<=16`, `0<=q<=8`, and `0<=r<=3`.
Each word is a canonical packed lowercase string over `a` through `o`, of
length at most 10. Its length occupies bits 40–43; symbol codes `a=1` through
`o=15` occupy successive low-to-high nibbles. All unused nibbles and bits
above bit 43 must be zero. The empty string is valid and is encoded as zero.
Dictionary entries must be pairwise distinct; queries may repeat or match no
entry. A null input, malformed frame, noncanonical word, duplicate dictionary
entry, or out-of-domain field returns `-1`. An empty dictionary and a zero
query count are valid and return zero.

For each query `j` (zero based), let `H_j` be the matching dictionary indices.
The result is

`sum over j of (j+1) * (17*|H_j| + sum(H_j))`.

The maximum valid input has 27 i64 words; one additional parseable word is
reserved for trailing-data rejection. The result is at most 14,112. The fixed
workspace cap is 4,096 bytes, including 16 node records, 11 child slots per
node, a traversal stack, two edit-distance rows, and alignment/ABI locals.

The build takes `O(n^2 L^2)` time in the worst case. The query phase takes
`O(q n L^2)` time in the worst case, and the tree and scratch use `O(nL)`
space for maximum word length `L<=10`.

## References and distinctness

The primary reference builds and searches the distance-labelled tree. The
independent reference does not construct a tree: it computes each query-word
distance with a full dynamic-programming matrix and scans the entire
dictionary. The package profiles the metric-tree index/search operation, not
Levenshtein distance alone. Local Levenshtein packages compute pairwise edit
distance; prefix tries and autocomplete packages use prefix structure and do
not prune by metric distance.

Algorithm provenance: Burkhard and Keller, “Some Approaches to Best-Match
File Searching,” *Communications of the ACM* 16(4), 1973,
[DOI 10.1145/362003.362025](https://doi.org/10.1145/362003.362025), especially
File Structure 1 and Search Algorithm 1. The paper partitions each recursive
subfile by its integer distance from a representative and uses the joint
cutoff criterion; the bounded profile implements that recursive partition as
an insertion-ordered BK-tree and applies the same metric interval pruning.
The reference text is used only for algorithm provenance. No source code,
prose, tests, examples, or fixtures are copied. See [RIGHTS.md](RIGHTS.md).

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/b/bk_tree_edit_distance_search.c`](../../../c/b/bk_tree_edit_distance_search.c) |
| C3 | [`c3/b/bk_tree_edit_distance_search.c3`](../../../c3/b/bk_tree_edit_distance_search.c3) |
| C++ | [`cpp/b/bk_tree_edit_distance_search.cpp`](../../../cpp/b/bk_tree_edit_distance_search.cpp) |
| Elisa | [`elisa/b/bk_tree_edit_distance_search.elisa`](../../../elisa/b/bk_tree_edit_distance_search.elisa) |
| Mojo | [`mojo/b/bk_tree_edit_distance_search.mojo`](../../../mojo/b/bk_tree_edit_distance_search.mojo) |
| Nim | [`nim/b/bk_tree_edit_distance_search.nim`](../../../nim/b/bk_tree_edit_distance_search.nim) |
| Odin | [`odin/b/bk_tree_edit_distance_search.odin`](../../../odin/b/bk_tree_edit_distance_search.odin) |
| Rust | [`rust/b/bk_tree_edit_distance_search.rs`](../../../rust/b/bk_tree_edit_distance_search.rs) |
| V | [`v/b/bk_tree_edit_distance_search.v`](../../../v/b/bk_tree_edit_distance_search.v) |
| Zig | [`zig/b/bk_tree_edit_distance_search.zig`](../../../zig/b/bk_tree_edit_distance_search.zig) |

The package is registered with the scalar runner and verifier. Its workload
frames, references, and static port inventory are linked above; no native
programs or checks have been run.
