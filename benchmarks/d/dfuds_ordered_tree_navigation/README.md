# DFUDS ordered-tree navigation

This package profiles the depth-first unary degree sequence (DFUDS)
representation in Chapter 641. It begins with a dummy opening bit, then emits
each node's degree as that many one bits followed by a zero, in depth-first
preorder. The result has exactly `2*n` bits for `n` nodes.

The signed-i64 input is:

```text
[n, q, parent[1..n-1], (opcode, node, argument) * q]
```

`n` is 1 through 31 and `q` is 0 through 32. Vertex 0 is the root; every
later vertex has a smaller-ID parent, and sibling order follows ascending
input ID. Query node IDs are zero-based depth-first preorder ordinals. Opcode
0 returns degree and requires argument 0. Opcode 1 returns the child at the
zero-based rank in `argument`, or `-1` when absent; ranks 0 through `n` are
parseable. Opcode 2 returns the parent, requires argument 0, and returns `-1`
for the root.

Output is little-endian signed-i64 words:

```text
[n, bit_length, packed_dfuds_bits, q, answer[0..q-1]]
```

Bit `j` of `packed_dfuds_bits` is DFUDS bit `j`, with bit 0 in the least
significant position. `bit_length` is `2*n`; unused high bits are zero. The
`n <= 31` bound keeps the packed sequence at most 62 bits, so its signed-i64
output word stays nonnegative. The maximum valid input is 128 words, and 129
words are accepted to classify one trailing word as invalid. Maximum output
and fixed workspace are 288 and 4096 bytes. Invalid input returns `-1`; null
output or insufficient capacity returns `-2`, with no bytes written.

The primary reference uses the chapter's balanced-parenthesis mappings. Here
`i` is the one-based first bit of a node's unary descriptor, and the package's
zero-based child rank is converted to the chapter's one-based `q`:
`degree(i) = next_0(i - 1) - i`,
`child(i,q) = findclose(i + degree(i) - q) + 1`, and
`parent(i) = prev_0(findopen(i - 1)) + 1`. Input/output node IDs map to the
first bit of each unary degree descriptor. The dummy opening-bit position
acts as the virtual-root marker for root-child parent queries; the real root's
parent is the benchmark sentinel `-1`. The independent reference builds
direct child lists and answers the same trace without consulting DFUDS.
Bounded scans use `O(n^2 + q*n)` work and `O(n+q)` fixed workspace; this does
not claim a constant-time rank/select index.

DFUDS is distinct from breadth-first LOUDS and from the depth-first BP
open/close representation. Existing balanced-parenthesis successor and
rank/unrank packages operate on strings and do not construct an ordered tree
or implement DFUDS degree/parent/child navigation.

Source: “Compressed Tree Representations,” *Encyclopedia of Algorithms*,
[Chapter 641](https://doi.org/10.1007/978-1-4939-2864-4_641), DFUDS subsection.
Only algorithm descriptions are used; the ports, references, and fixtures are
clean-room.

## Ports

| Language | Source |
|---|---|
| C | `c/d/dfuds_ordered_tree_navigation.c` |
| C3 | `c3/d/dfuds_ordered_tree_navigation.c3` |
| C++ | `cpp/d/dfuds_ordered_tree_navigation.cpp` |
| Elisa | `elisa/d/dfuds_ordered_tree_navigation.elisa` |
| Mojo | `mojo/d/dfuds_ordered_tree_navigation.mojo` |
| Nim | `nim/d/dfuds_ordered_tree_navigation.nim` |
| Odin | `odin/d/dfuds_ordered_tree_navigation.odin` |
| Rust | `rust/d/dfuds_ordered_tree_navigation.rs` |
| V | `v/d/dfuds_ordered_tree_navigation.v` |
| Zig | `zig/d/dfuds_ordered_tree_navigation.zig` |

`primary_oracle.py` is the DFUDS balanced-parenthesis reference;
`independent_oracle.py` follows the explicit tree. `check_inventory.py` is a
static metadata and source inventory checker; it is not run as part of this
source-only addition.
