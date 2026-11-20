# Discrete interval encoding tree

This benchmark traces a discrete interval encoding tree (DIET), a binary
search tree whose nodes store maximal runs of adjacent integers. It supports
point insertion, point deletion, and membership lookup. The output records the
set size and tree compression after every operation, along with the queried
key's membership.

## Contract

The ABI is `i64_array_bytes_output`, exported symbol
`discrete_interval_encoding_tree`. Input is
`[Q, (opcode, key)*Q]`, with `0 <= Q <= 32` and keys in `[-15, 15]`.
Opcode 0 inserts a key, opcode 1 deletes it, and opcode 2 queries membership.
Insertion of an existing key and deletion of an absent key are no-ops. The
initial set is empty. The tree is an unbalanced BST ordered by interval
endpoints; each node stores one closed interval `[lo, hi]`. Intervals are
disjoint, non-adjacent, and ordered by the BST relation.

When insertion extends an interval at either endpoint, the implementation
also fuses the interval with an adjacent predecessor or successor if present.
Deleting an interval endpoint shortens it; deleting a singleton removes its
node and joins its subtrees using the maximum interval from the left subtree
when both sides exist; deleting an interior key splits its interval and places
the right piece at the root of the former right subtree. No balancing is
performed. Each source operation is validated before output-capacity checks.

After each operation, let `p` be whether `key` is now present, `c` the set
cardinality, and `t` the number of interval nodes. One signed i64 is emitted as
`64*c + 2*t + p`, serialized little-endian. Here `0 <= c <= 31`, `0 <= t <=
16`, and `p` is 0 or 1, so the fields decode without overlap. The exact frame
is `1 + 2*Q`: 65 input words are valid at the maximum and 66 parseable words
allow a trailing-word rejection. Output is at most 256 bytes. Malformed input
returns `-1`; null or undersized output returns `-2` without writing. A valid
empty trace returns zero and permits a null output buffer.

The source operation paths take O(h) time, where h is the unbalanced tree
height; predecessor/successor fusion and subtree joining follow a path of at
most h as well. A Q-operation trace is O(Q²) in the worst case because the
height can grow linearly. The fixed arena holds 64 nodes: at most one node can
be allocated for each insertion and one for each interior deletion. The
workspace cap is 8,192 bytes, including the node arena, recursion frames,
parsed fields, and output staging; caller input/output are excluded.

## References and workload

[`primary_oracle.py`](primary_oracle.py) follows the interval-BST operations.
[`independent_oracle.py`](independent_oracle.py) uses a 31-bit membership map
and counts maximal runs directly. [`workload.json`](workload.json) includes
bridging fusion, interior deletion and split, duplicate/absent operations,
empty and null frames, capacity handling, and maximum valid/parseable lengths.
The package-local workload and source inventory helpers are static and have not
been run.

## Provenance and duplicate check

NIST DADS identifies DIET as a binary search tree storing consecutive values
as intervals. Erwig's paper specifies membership, insertion with neighbor
fusion, and deletion with endpoint shortening, singleton removal, and
interior splitting. This profile is a point-set BST, distinct from the local
[`interval_container`](../../i/interval_container/README.md), which uses a
sorted interval list for half-open range addition/subtraction and returns
covered length. The local
[`common_interval_decomposition_tree`](../common_interval_decomposition_tree/README.md)
decomposes permutation intervals into strong components; it does not maintain
an integer set or fuse/split adjacent key runs. The bitmap reference is a
correctness cross-check, not an implementation of the tree method.

## Language ports

| Language | Source |
|---|---|
| C | [c/d/discrete_interval_encoding_tree.c](../../../c/d/discrete_interval_encoding_tree.c) |
| C3 | [c3/d/discrete_interval_encoding_tree.c3](../../../c3/d/discrete_interval_encoding_tree.c3) |
| C++ | [cpp/d/discrete_interval_encoding_tree.cpp](../../../cpp/d/discrete_interval_encoding_tree.cpp) |
| Elisa | [elisa/d/discrete_interval_encoding_tree.elisa](../../../elisa/d/discrete_interval_encoding_tree.elisa) |
| Mojo | [mojo/d/discrete_interval_encoding_tree.mojo](../../../mojo/d/discrete_interval_encoding_tree.mojo) |
| Nim | [nim/d/discrete_interval_encoding_tree.nim](../../../nim/d/discrete_interval_encoding_tree.nim) |
| Odin | [odin/d/discrete_interval_encoding_tree.odin](../../../odin/d/discrete_interval_encoding_tree.odin) |
| Rust | [rust/d/discrete_interval_encoding_tree.rs](../../../rust/d/discrete_interval_encoding_tree.rs) |
| V | [v/d/discrete_interval_encoding_tree.v](../../../v/d/discrete_interval_encoding_tree.v) |
| Zig | [zig/d/discrete_interval_encoding_tree.zig](../../../zig/d/discrete_interval_encoding_tree.zig) |

All ten ports are registered in the shared `i64_array_bytes_output` runner
and verifier. The root README, catalog, and expansion ledger include this
profile.
