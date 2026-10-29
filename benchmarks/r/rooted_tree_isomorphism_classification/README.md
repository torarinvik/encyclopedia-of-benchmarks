# Rooted Tree Isomorphism Classification

Classify a list of rooted, unlabeled trees by rooted isomorphism. The implementations compute bottom-up child-type signatures: each node is represented by the sorted multiset of its children's canonical types. Signatures are interned by exact tuple equality, so vertex labels, edge order, and edge direction in the packed input do not affect the result.

## Contract

- Input is `[tree_count, (vertex_count, root, edge_u, edge_v...)*]`. Each tree record contains exactly `vertex_count - 1` undirected edges.
- There are 1 through 16 trees, each with 1 through 32 vertices, and at most 128 vertices total. Vertex IDs and roots are zero-based.
- Each tree must be connected, acyclic, loop-free, and have no duplicate undirected edge. Extra or missing input values are invalid.
- Output is one byte per input tree. A rooted-isomorphism class receives the next label starting at zero when its first tree occurs; later isomorphic trees reuse that label. Thus labels fit in `[0, 15]`.
- Malformed input returns `-1`. A valid input with null output or capacity below `tree_count` returns `-2` and writes no bytes. A successful call returns `tree_count` and writes exactly that many bytes.
- The largest parseable input is 1,025 values, while the total-vertex constraint limits valid inputs to at most 257 values. The result depends on exact canonical signatures, not hashes.

## Algorithm

For each tree, an iterative traversal records parent links and postorder. In reverse order, each vertex collects the canonical types of its children, sorts those type IDs, and interns the resulting sequence. The root type identifies the rooted tree exactly. A separate first-occurrence pass maps root types to the output labels.

For a forest with `V` total vertices, this bounded implementation uses `O(V²)` time and `O(V²)` static signature storage. The time bound includes adjacency scans, insertion sorting of child types, and exact signature-table comparisons.

## Workload and provenance

[`workload.json`](workload.json) covers rooted paths with different roots, relabeled and reordered stars, malformed trees, output-capacity errors, and null pointers. The task is based on the [Library Checker Rooted Tree Isomorphism Classification problem](https://judge.yosupo.jp/problem/rooted_tree_isomorphism_classification). The problem is used as an algorithm reference only; no submission code, tests, problem statement, or text was copied.

The recursive nested-tuple oracle and static workload checker are in [`rooted_tree_isomorphism_classification_oracle.py`](../../rooted_tree_isomorphism_classification_oracle.py) and [`rooted_tree_isomorphism_classification_verifier.py`](../../rooted_tree_isomorphism_classification_verifier.py). Compilation and runtime verification have not been performed.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/rooted_tree_isomorphism_classification.c](../../../c/r/rooted_tree_isomorphism_classification.c) |
| C3 | [c3/r/rooted_tree_isomorphism_classification.c3](../../../c3/r/rooted_tree_isomorphism_classification.c3) |
| C++ | [cpp/r/rooted_tree_isomorphism_classification.cpp](../../../cpp/r/rooted_tree_isomorphism_classification.cpp) |
| Elisa | [elisa/r/rooted_tree_isomorphism_classification.elisa](../../../elisa/r/rooted_tree_isomorphism_classification.elisa) |
| Nim | [nim/r/rooted_tree_isomorphism_classification.nim](../../../nim/r/rooted_tree_isomorphism_classification.nim) |
| Odin | [odin/r/rooted_tree_isomorphism_classification.odin](../../../odin/r/rooted_tree_isomorphism_classification.odin) |
| Rust | [rust/r/rooted_tree_isomorphism_classification.rs](../../../rust/r/rooted_tree_isomorphism_classification.rs) |
| V | [v/r/rooted_tree_isomorphism_classification.v](../../../v/r/rooted_tree_isomorphism_classification.v) |
| Zig | [zig/r/rooted_tree_isomorphism_classification.zig](../../../zig/r/rooted_tree_isomorphism_classification.zig) |
