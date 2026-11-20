# Zhang–Shasha ordered tree edit distance

This package computes unit-cost edit distance between two rooted, ordered,
node-labeled trees. The primary benchmark uses Zhang and Shasha's keyroot
forest-distance dynamic program. It is distinct from string edit distance,
which operates on sequences, and from rooted-tree isomorphism, which compares
shape without computing insertion, deletion, or relabel costs.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`ordered_tree_edit_distance_zhang_shasha`.

Input is `[N1,N2,labels1[N1],parents1[N1],labels2[N2],parents2[N2]]`.
Each tree has 1–8 vertices, labels are integers in `0..3`, and the root is
vertex 0 with parent `-1`. Vertices are supplied in preorder. Every other
parent ID must be smaller than its child ID, and the parent sequence must
describe a valid preorder traversal. Children inherit their order from their
increasing vertex IDs. The exact input length is `2+2*N1+2*N2`; the maximum
valid and parseable lengths are 34 and 35 signed 64-bit values.

An insertion adds one node, a deletion removes one node while promoting its
children in order, and a relabel changes one node's label. Each operation
costs one; the result is the minimum total cost. Invalid input and a null
input pointer return `-1`. A valid result is between 0 and 16.

The primary oracle converts each input tree to postorder, computes each node's
leftmost-leaf descendant, and evaluates the forest recurrence for each pair of
keyroots. The independent oracle enumerates partial node mappings and accepts
only mappings that preserve ancestor relations and left-to-right order; the
mapping cost is the number of unmatched nodes plus relabel costs. This
exhaustive reference is bounded to eight vertices per tree, matching the
workload's maximum size.

## Sources and rights

The primary method is from Zhang and Shasha, [“Simple Fast Algorithms for the
Editing Distance Between Trees and Related Problems,” *SIAM Journal on
Computing* 18(6), 1989](https://doi.org/10.1137/0218082). The operation and
structure-preserving mapping formulation is also described in Tai, [“The
Tree-to-Tree Correction Problem,” *Journal of the ACM* 26(3),
1979](https://doi.org/10.1145/322139.322143). These references are used for
mathematical algorithm descriptions only. No source code, prose, fixtures, or
figures are reproduced; see [RIGHTS.md](RIGHTS.md).

## Package files

- Primary reference: [primary_oracle.py](primary_oracle.py)
- Independent reference: [independent_oracle.py](independent_oracle.py)
- Fixtures: [workload.json](workload.json)
- Static package inventory: [verify_package.py](verify_package.py)

Language ports:

- [C](../../../c/o/ordered_tree_edit_distance_zhang_shasha.c)
- [C3](../../../c3/o/ordered_tree_edit_distance_zhang_shasha.c3)
- [C++](../../../cpp/o/ordered_tree_edit_distance_zhang_shasha.cpp)
- [Elisa](../../../elisa/o/ordered_tree_edit_distance_zhang_shasha.elisa)
- [Mojo](../../../mojo/o/ordered_tree_edit_distance_zhang_shasha.mojo)
- [Nim](../../../nim/o/ordered_tree_edit_distance_zhang_shasha.nim)
- [Odin](../../../odin/o/ordered_tree_edit_distance_zhang_shasha.odin)
- [Rust](../../../rust/o/ordered_tree_edit_distance_zhang_shasha.rs)
- [V](../../../v/o/ordered_tree_edit_distance_zhang_shasha.v)
- [Zig](../../../zig/o/ordered_tree_edit_distance_zhang_shasha.zig)
