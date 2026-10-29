# Dominator tree

Compute the immediate dominator of every vertex in a directed graph relative to a selected root. A vertex `d` dominates `v` when every path from the root to `v` contains `d`; the immediate dominator is the closest strict dominator. The root is its own parent. Vertices unreachable from the root use byte value `255`.

## Contract

- Input is `[vertex_count, root, edge_count, (from, to) * edge_count]`, using zero-based vertex IDs.
- There are 1–63 vertices and 0–2,047 directed edges. Input length must equal `3 + 2 * edge_count`.
- Repeated edges are coalesced. Self-loops are allowed. Edges from unreachable vertices do not affect reachable dominators.
- The output is one byte per vertex, in vertex-ID order. Each reachable vertex contains its immediate-dominator ID; the root contains its own ID. An unreachable vertex contains `255`.
- Malformed input returns `-1`. An absent output buffer or capacity below `vertex_count` returns `-2`. Success returns the number of output bytes.

The implementations use the standard dominator data-flow equations with fixed-width bitsets: initialize each reachable non-root set to all reachable vertices, repeatedly intersect the sets of reachable predecessors and add the vertex itself, then select the strict dominator with the deepest dominator set. The independent oracle uses Python sets. With at most 63 vertices, each set fits in one 64-bit word. The conservative worst-case bound for this direct fixed-point implementation is `O(V^4)` bit operations and `O(V)` machine words; reachability takes `O(V + E)` time. The implementation favors a compact, comparable workload over the more involved Lengauer–Tarjan union-find algorithm.

## Sources

- [Library Checker: Dominator Tree](https://judge.yosupo.jp/problem/dominatortree) defines the root-relative immediate-dominator problem. This package uses the common convention that the root is its own parent and assigns `255` to unreachable vertices.
- Cooper, Harvey, and Kennedy, [A Simple, Fast Dominance Algorithm](https://hipersoft.cs.rice.edu/grads/publications/dom14.pdf), describes the iterative data-flow formulation used here. The ports are independent implementations of the equations, not copied source code.

The workload is [`workload.json`](workload.json). The package-local set-based oracle is [`../dominator_tree_oracle.py`](../dominator_tree_oracle.py); [`../verify_dominator_tree_oracle.py`](../verify_dominator_tree_oracle.py) checks its published workload encodings without launching benchmark binaries.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/d/dominator_tree.c](../../../c/d/dominator_tree.c) |
| C3 | [c3/d/dominator_tree.c3](../../../c3/d/dominator_tree.c3) |
| C++ | [cpp/d/dominator_tree.cpp](../../../cpp/d/dominator_tree.cpp) |
| Elisa | [elisa/d/dominator_tree.elisa](../../../elisa/d/dominator_tree.elisa) |
| Nim | [nim/d/dominator_tree.nim](../../../nim/d/dominator_tree.nim) |
| Odin | [odin/d/dominator_tree.odin](../../../odin/d/dominator_tree.odin) |
| Rust | [rust/d/dominator_tree.rs](../../../rust/d/dominator_tree.rs) |
| V | [v/d/dominator_tree.v](../../../v/d/dominator_tree.v) |
| Zig | [zig/d/dominator_tree.zig](../../../zig/d/dominator_tree.zig) |
