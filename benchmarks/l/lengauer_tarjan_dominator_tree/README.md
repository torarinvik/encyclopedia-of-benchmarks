# Lengauer–Tarjan dominator tree

Compute the immediate dominator of each vertex reachable from a selected root in a directed graph. The root is its own immediate dominator, and unreachable vertices are encoded as byte `255`. The input is `[V,root,E,(from,to)*E]` with zero-based vertex IDs, `1<=V<=63`, and `0<=E<=2047`; repeated arcs are coalesced and self-loops are allowed. The output is one byte per vertex in vertex order. Invalid input returns `-1`; a null or too-small output buffer returns `-2` without writes.

The implementation follows the simple Lengauer–Tarjan method: an iterative depth-first traversal assigns numbers, reverse DFS order computes semidominators using predecessor lists and path-compressed `LINK`/`EVAL`, buckets resolve provisional dominators, and a forward pass finalizes them. Its bounded complexity is `O((V+E) log V)` time and `O(V+E)` storage.

The existing [`dominator_tree`](../../d/dominator_tree/README.md) package has the same immediate-dominator contract, but uses iterative bitset data-flow intersections. This package benchmarks the semidominator and path-compression algorithm specifically, so the shared output semantics do not make the methods duplicates.

The primary oracle independently implements the simple Lengauer–Tarjan steps. The verifier oracle instead removes each reachable vertex in turn and searches the remaining graph to find dominators, then identifies the nearest strict dominator. Workload fixtures are in [`workload.json`](workload.json); the package-local source and fixture inventory checker is [`verify_lengauer_tarjan_dominator_tree_package.py`](verify_lengauer_tarjan_dominator_tree_package.py).

The verifier source also specifies every directed graph, including self-loops,
through three vertices with every root, comparing the two references. These
checks have not been executed.

## Source and rights

The method is attributed to Lengauer and Tarjan, [“A Fast Algorithm for Finding Dominators in a Flowgraph,”](https://doi.org/10.1145/357062.357071) *ACM Transactions on Programming Languages and Systems* 1(1), 1979. The [author-hosted paper copy](https://www.cs.princeton.edu/courses/archive/fall03/cs528/handouts/a%20fast%20algorithm%20for%20finding.pdf) describes the simple path-compression variant and its `O(m log n)` bound. The paper retains ACM copyright; only its high-level algorithm description informed these clean-room implementations.

## Language ports

- [C](../../../c/l/lengauer_tarjan_dominator_tree.c)
- [C3](../../../c3/l/lengauer_tarjan_dominator_tree.c3)
- [C++](../../../cpp/l/lengauer_tarjan_dominator_tree.cpp)
- [Elisa](../../../elisa/l/lengauer_tarjan_dominator_tree.elisa)
- [Mojo](../../../mojo/l/lengauer_tarjan_dominator_tree.mojo)
- [Nim](../../../nim/l/lengauer_tarjan_dominator_tree.nim)
- [Odin](../../../odin/l/lengauer_tarjan_dominator_tree.odin)
- [Rust](../../../rust/l/lengauer_tarjan_dominator_tree.rs)
- [V](../../../v/l/lengauer_tarjan_dominator_tree.v)
- [Zig](../../../zig/l/lengauer_tarjan_dominator_tree.zig)
