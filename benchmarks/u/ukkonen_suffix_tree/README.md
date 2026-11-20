# Ukkonen online suffix tree

Ukkonen's algorithm builds a suffix tree one symbol at a time from left to
right. Each phase updates an active reference point, uses suffix links to move
between related suffixes, and keeps leaf edge ends open so the new symbol
extends all current leaves together. Edge splitting and canonization make the
implicit suffixes explicit as later symbols arrive. A unique terminal symbol
turns every suffix into a leaf.

## Contract

The scalar ABI receives `[n, symbol_0, ..., symbol_(n-1)]`, where `n` is 0..64
and symbols are 0..3. The implementation appends terminal symbol 4 and
constructs its suffix tree online. Framing must be exact; null or invalid input
returns `-1`.

The result packs the canonical tree's node count, number of distinct nonempty
substrings, and a structural checksum. Canonical preorder visits children by
their first symbol. Tokens distinguish edges, leaves, internal nodes, and
closing boundaries; leaf tokens include the suffix start. The checksum is the
one-based rank-weighted sum of those tokens. The distinct-substring count sums
the nonterminal symbols along all edges.

The primary reference implements the online active-point/suffix-link update.
The independent reference inserts all terminal-extended suffixes into a plain
suffix trie and compresses unary paths. These are different construction
procedures that serialize the same tree.

This package is distinct from local [`suffix_tree`](../../s/suffix_tree/README.md),
which inserts suffixes directly, and
[`suffix_tree_from_sa_lcp`](../../s/suffix_tree_from_sa_lcp/README.md), which
constructs from a suffix array and LCP values. The
[`suffix_tree_pattern_occurrences`](../../s/suffix_tree_pattern_occurrences/README.md)
package also inserts suffixes and adds pattern-query behavior; none uses
Ukkonen's active-point and suffix-link construction.

## Reference

Esko Ukkonen, “On-line Construction of Suffix Trees,” *Algorithmica* 14
(1995), 249–260, [DOI 10.1007/BF01206331](https://doi.org/10.1007/BF01206331).
Only the algorithm description is used; no source code is copied.

## Implementations

| Language | Source |
|---|---|
| C | [c/u/ukkonen_suffix_tree.c](../../../c/u/ukkonen_suffix_tree.c) |
| C3 | [c3/u/ukkonen_suffix_tree.c3](../../../c3/u/ukkonen_suffix_tree.c3) |
| C++ | [cpp/u/ukkonen_suffix_tree.cpp](../../../cpp/u/ukkonen_suffix_tree.cpp) |
| Elisa | [elisa/u/ukkonen_suffix_tree.elisa](../../../elisa/u/ukkonen_suffix_tree.elisa) |
| Mojo | [mojo/u/ukkonen_suffix_tree.mojo](../../../mojo/u/ukkonen_suffix_tree.mojo) |
| Nim | [nim/u/ukkonen_suffix_tree.nim](../../../nim/u/ukkonen_suffix_tree.nim) |
| Odin | [odin/u/ukkonen_suffix_tree.odin](../../../odin/u/ukkonen_suffix_tree.odin) |
| Rust | [rust/u/ukkonen_suffix_tree.rs](../../../rust/u/ukkonen_suffix_tree.rs) |
| V | [v/u/ukkonen_suffix_tree.v](../../../v/u/ukkonen_suffix_tree.v) |
| Zig | [zig/u/ukkonen_suffix_tree.zig](../../../zig/u/ukkonen_suffix_tree.zig) |

The bounded cases and packed expected results are in
[`workload.json`](workload.json).
