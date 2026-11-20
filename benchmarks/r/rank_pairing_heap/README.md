# Type-1 rank-pairing heap

This benchmark implements a Type-1 rank-pairing heap in the paper's binary
half-ordered representation. Trees may become arbitrarily unbalanced. A
decrease-key cuts one node and repairs ranks along its former ancestor path;
delete-min disassembles the root's right spine and fairly links equal-rank
roots. This is distinct from the local pairing heap's two-pass melding, the
Fibonacci heap's cascading cuts, and the hollow heap's lazy relocation into
new nodes.

## Contract

The `i64_array_scalar` input is `[m, (opcode, item_id, value)*m]`, with
`0 <= m <= 64`, exact length `1 + 3*m`, maximum valid length 193, and maximum
parseable length 194. Item IDs are in `0..31`; keys are in `0..1_000_000`.

- Opcode `1` inserts an inactive item ID with the given key.
- Opcode `2` strictly decreases the key of an active item.
- Opcode `3` deletes the minimum and requires both operands to be 0.
- Opcode `4` finds the minimum and requires both operands to be 0.

An item ID may be reused after delete-min removes it. Find-min and delete-min
each add `(one_based_operation_index * (key + 1)) + item_id` to the result.
Invalid, null, or incorrectly sized input returns `-1`; a valid trace with no
query or minimum deletion returns `0`.

Each node stores its key, rank, and binary `left`, `right`, and `parent`
indices; a missing child has rank `-1`. Insert creates a rank-zero root. On a
nonroot decrease, replace the node by its right child in its parent's binary
tree, make the decreased node a root with `rank(left)+1`, then apply the
Type-1 rank-decrease rule up the former parent path. A root decrease changes
only its key. During delete-min, each node on the removed root's left child's
right spine becomes a root with rank `rank(left)+1`. The ports fully link
equal-rank roots after that disassembly; this is an allowed fair-linking
choice for the rank-pairing structure. Ties compare roots by
`(key, item_id, node_creation_index)`. Repeatedly link the lowest rank with a
duplicate, selecting its two lowest node indices.

The bounded indexed implementations use `O(m^2)` time and `O(m)` space.
The underlying Type-1 rank-pairing heap has amortized `O(1)` insert and
decrease-key and `O(log n)` delete-min.

Two independent references and a workload cover rank repair, tree cuts,
equal keys, item-ID reuse, invalid operations, and the maximum frame. Sources
and contracts were reviewed statically; programs and checks have not been
run.

| Language | Port |
|---|---|
| C | [c/r/rank_pairing_heap.c](../../../c/r/rank_pairing_heap.c) |
| C3 | [c3/r/rank_pairing_heap.c3](../../../c3/r/rank_pairing_heap.c3) |
| C++ | [cpp/r/rank_pairing_heap.cpp](../../../cpp/r/rank_pairing_heap.cpp) |
| Elisa | [elisa/r/rank_pairing_heap.elisa](../../../elisa/r/rank_pairing_heap.elisa) |
| Mojo | [mojo/r/rank_pairing_heap.mojo](../../../mojo/r/rank_pairing_heap.mojo) |
| Nim | [nim/r/rank_pairing_heap.nim](../../../nim/r/rank_pairing_heap.nim) |
| Odin | [odin/r/rank_pairing_heap.odin](../../../odin/r/rank_pairing_heap.odin) |
| Rust | [rust/r/rank_pairing_heap.rs](../../../rust/r/rank_pairing_heap.rs) |
| V | [v/r/rank_pairing_heap.v](../../../v/r/rank_pairing_heap.v) |
| Zig | [zig/r/rank_pairing_heap.zig](../../../zig/r/rank_pairing_heap.zig) |

The Type-1 algorithm follows Haeupler, Sen, and Tarjan's [Rank-Pairing
Heaps](https://doi.org/10.1137/100785351) ([author-hosted
paper](https://oar.princeton.edu/bitstream/88435/pr1j53c/1/RankPairingHeaps.pdf)).
Only algorithmic ideas are used; implementations and fixtures are
independently written.
