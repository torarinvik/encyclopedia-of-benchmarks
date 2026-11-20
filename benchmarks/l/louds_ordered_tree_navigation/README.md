# LOUDS ordered-tree navigation

This package profiles the LOUDS (level-order unary degree sequence)
representation in Chapter 641. A node of degree `d` contributes `d` one bits
followed by a zero, and node codes are concatenated in breadth-first order.
For `n` nodes the bit string has exactly `2*n-1` bits.

The signed-i64 input is:

```text
[n, q, parent[1..n-1], (opcode, node, argument) * q]
```

`n` is 1 through 32 and `q` is 0 through 32. Vertex 0 is the root, and
`parent[v]` must satisfy `0 <= parent[v] < v`; this gives a rooted ordered tree
whose siblings are ordered by vertex ID. Query node IDs are zero-based LOUDS
breadth-first IDs. Opcode 0 returns degree and opcode 1 returns parent (the
root's parent is `-1`); both require argument 0. Opcode 2 returns the child
with zero-based rank `argument`, or `-1` when that rank is absent. Child ranks
from 0 through `n` are parseable.

Output is little-endian signed-i64 words:

```text
[n, bit_length, packed_louds_bits, q, answer[0..q-1]]
```

Bit `j` of `packed_louds_bits` is bit `j` of the LOUDS sequence, with bit 0
stored in the least-significant position. `bit_length` is `2*n-1`; unused high
bits are zero. The maximum valid input is 129 words, and 130 words are accepted
to classify one trailing word as invalid. Maximum output and fixed workspace
are 288 and 4096 bytes. Invalid input returns `-1`; null output or insufficient
capacity returns `-2`, with no bytes written.

The ports build LOUDS with a breadth-first queue. They derive degree from
successive `select_0` positions and use prefix `rank_1` counts to map parents
and child intervals. These bounded scans implement the chapter's navigation
mapping without claiming the constant-time succinct rank/select index. The
primary reference follows the LOUDS bit positions; the independent reference
answers queries from direct parent/child lists.

This representation differs from [`wavelet_tree`](../../w/wavelet_tree/README.md),
which partitions value sequences, from the raw bitvector operations in
[`rank_select_bitstring`](../../r/rank_select_bitstring/README.md), from
[`balanced_parenthesis_successor`](../../b/balanced_parenthesis_successor/README.md),
which advances a parenthesis string, and from binary-tree serializers that do
not represent general ordered rooted trees.

## Chapter subsection audit

The chapter's Key Results section distinguishes three encodings. This package
implements the LOUDS subsection's unary degree string in breadth-first order
and profiles its degree, parent, and child navigation relations using bounded
rank/select scans. The source also gives BP and DFUDS as different ordered-tree
representations. BP uses a depth-first open/close sequence and its fully
functional variant adds excess-value range-min/max searches for operations
such as matching parentheses and enclosure. DFUDS stores unary degree codes
in depth-first order, adds a dummy opening bit, and derives degree, child, and
parent through balanced-parenthesis operations. Those are distinct profiles:
the local `balanced_parenthesis_successor` and
`balanced_parenthesis_rank_unrank` packages cover string successor and
rank/unrank operations, not BP ordered-tree navigation, and no local DFUDS
package was found. Keep BP tree navigation and DFUDS as separate candidates;
neither is claimed covered by this LOUDS benchmark.

The chapter's LOUDS subsection also explicitly limits efficient navigation:
depth, subtree size, and LCA are not efficiently supported by LOUDS alone. This
profile therefore excludes them. The static implementation scans the bounded
representation and does not claim the chapter's constant-time indexed
rank/select implementation.

Source: “Compressed Tree Representations,” *Encyclopedia of Algorithms*,
[Chapter 641](https://doi.org/10.1007/978-1-4939-2864-4_641), Key Results and
the LOUDS, BP Representation, DFUDS, and Fully Functional BP Representation
subsections. Only the LOUDS encoding and its stated degree/parent/child
relations define this package. Algorithm description only; ports and fixtures
are clean-room.

## Ports

| Language | Source |
|---|---|
| C | `c/l/louds_ordered_tree_navigation.c` |
| C3 | `c3/l/louds_ordered_tree_navigation.c3` |
| C++ | `cpp/l/louds_ordered_tree_navigation.cpp` |
| Elisa | `elisa/l/louds_ordered_tree_navigation.elisa` |
| Mojo | `mojo/l/louds_ordered_tree_navigation.mojo` |
| Nim | `nim/l/louds_ordered_tree_navigation.nim` |
| Odin | `odin/l/louds_ordered_tree_navigation.odin` |
| Rust | `rust/l/louds_ordered_tree_navigation.rs` |
| V | `v/l/louds_ordered_tree_navigation.v` |
| Zig | `zig/l/louds_ordered_tree_navigation.zig` |

`primary_oracle.py` is the LOUDS rank/select reference and
`independent_oracle.py` is the direct-tree reference. `check_inventory.py` is a
static metadata/source inventory checker; it is not executed as part of this
source-only addition.
