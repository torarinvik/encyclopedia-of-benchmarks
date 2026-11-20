# Same-fringe leaf iterator

This benchmark compares two full binary trees by their ordered leaf labels. The trees may have different shapes and different internal-node labels. A primary validation pass checks each tree table; two explicit depth-first stacks then yield one leaf from each tree at a time, so a leaf-value mismatch stops the comparison without constructing either complete fringe.

## Contract

- ABI: `int64_t same_fringe_leaf_iterator(const int64_t *input, size_t length)`.
- Input: `[nA, nB, recordsA..., recordsB...]`. Each tree has 1–15 nodes; the total is at most 30. A local node record is `[value, left_child, right_child]`, and root node 0 is implicit.
- A leaf has `left_child = right_child = -1`. An internal node has two distinct child indices in `0..n-1`; unary nodes are invalid. Child indices are local to each tree's table. Internal values are ignored; leaf values are signed i64 labels.
- Each table must describe one connected, acyclic, full binary tree rooted at 0. Every nonroot node has exactly one parent; repeated children, shared nodes, cycles, unreachable records, and a parent for root 0 are invalid.
- Exact input length is `2 + 3*(nA+nB)`, at most 92 words. The parseable frame cap is 93 words to reject one trailing word. Null or malformed input returns `-1`.
- Return `1` when both left-to-right leaf-label sequences are equal, `0` when they differ, and `-1` for invalid input.

Validation inspects every node before comparison, which makes malformed-tree handling deterministic. After validation, the primary iterator pushes right before left so the stack yields leaves from left to right. It compares a pair as soon as both labels are available and returns at the first mismatch; if one iterator ends first, the fringes differ.

The native validation scratch uses at most three 15-entry arrays (visited flags, parent counts, and a DFS stack), conservatively 360 bytes when each entry is charged as i64. The comparison then uses two 15-entry index stacks (240 bytes). Validation and comparison use separate phases, so live native array storage is at most about 600 bytes plus scalar locals; the contract allows 1,024 bytes. The input buffer is caller-owned and is excluded. Worst-case time is linear in the total node count; the comparison work after validation is proportional to the common leaf prefix plus at most one next leaf per tree.

The independent reference recursively validates each tree, materializes its full left-to-right leaf list, and compares the two lists. That differs from the primary's lockstep stack iterators.

This is not [`flatten_nested_list`](../../f/flatten_nested_list/README.md), which flattens nested lists and returns a leaf-sequence hash, or a tree traversal that serializes a whole tree. The distinct output here is a Boolean relation between two independently supplied tree fringes, with explicit first-mismatch termination.

## RosettaCodeData title-band cross-check

The pinned 35–33 title band also contains Strassen matrix multiplication, Stirling numbers of the second kind, Juggler sequence, Thiele interpolation, Kosaraju, Hierholzer, Vogel's approximation method, and rooted-tree listing; local packages already cover those named methods. The binomial-transform title overlaps the fixed modulo-three `coloured_triangle_reduction` profile only in its underlying transform identity, so it is not marked as an exact duplicate. The `Same-fringe` title is a distinct tree-comparison contract with no local same-fringe or leaf-stream comparison package.

## Source and provenance

The academic algorithm source is Biernacki, Danvy, and Shan, “On the static and dynamic extents of delimited continuations,” *Science of Computer Programming* 60 (2006), §4, [DOI 10.1016/j.scico.2006.01.002](https://doi.org/10.1016/j.scico.2006.01.002); an [author-hosted paper copy](https://www.cs.tufts.edu/comp/150FP/archive/olivier-danvy/sdarticle.pdf) presents eager, lazy, and stack-based generators and the lockstep stop condition. Finin and Rutter's earlier “Different Fringe for Different Folk” provides additional iterator motivation ([archived scan](https://ebiquity.umbc.edu/_file_directory_/papers/1148.pdf)). The pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used for title discovery only. No task text, source code, examples, or tests were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/same_fringe_leaf_iterator.c`](../../../c/s/same_fringe_leaf_iterator.c) |
| C3 | [`c3/s/same_fringe_leaf_iterator.c3`](../../../c3/s/same_fringe_leaf_iterator.c3) |
| C++ | [`cpp/s/same_fringe_leaf_iterator.cpp`](../../../cpp/s/same_fringe_leaf_iterator.cpp) |
| Elisa | [`elisa/s/same_fringe_leaf_iterator.elisa`](../../../elisa/s/same_fringe_leaf_iterator.elisa) |
| Mojo | [`mojo/s/same_fringe_leaf_iterator.mojo`](../../../mojo/s/same_fringe_leaf_iterator.mojo) |
| Nim | [`nim/s/same_fringe_leaf_iterator.nim`](../../../nim/s/same_fringe_leaf_iterator.nim) |
| Odin | [`odin/s/same_fringe_leaf_iterator.odin`](../../../odin/s/same_fringe_leaf_iterator.odin) |
| Rust | [`rust/s/same_fringe_leaf_iterator.rs`](../../../rust/s/same_fringe_leaf_iterator.rs) |
| V | [`v/s/same_fringe_leaf_iterator.v`](../../../v/s/same_fringe_leaf_iterator.v) |
| Zig | [`zig/s/same_fringe_leaf_iterator.zig`](../../../zig/s/same_fringe_leaf_iterator.zig) |

`workload.json` contains equal/different shape fixtures, first/middle/last mismatch cases, maximum-size trees, framing errors, and malformed trees. `verify_workload.py` compares fixture outputs with both references; `check_inventory.py` records source paths, ABI exports, null guards, documentation links, and provenance. These static helpers were written but not run.
