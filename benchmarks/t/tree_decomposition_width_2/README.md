# Tree Decomposition (Width 2)

This package recognizes bounded simple undirected graphs of treewidth at most
2 and emits a tree-decomposition certificate. It is distinct from the local
treewidth ordering profiles, which report elimination orders and heuristic
widths but do not construct a decomposition certificate.

## Bounded profile

The ABI is `i64_array_bytes_output`, with symbol
`tree_decomposition_width_2`. Input is `[N,M,u0,v0,...]`, using zero-based
vertex IDs and canonical undirected edges `u0 < v0`. The local limits are
`1 <= N <= 32` and `0 <= M <= 64`; loops, repeated edges, noncanonical edge
orientation, and malformed frames return `-1`.

The algorithm repeatedly removes the smallest-ID active vertex whose current
degree is at most two, first adding the edge between its two active neighbors
when needed. If no such vertex exists, the graph is outside the width-2
profile and the call returns `-1`. For every removed vertex, its bag contains
that vertex and its active neighbors. Each bag attaches to the bag of its
earliest-eliminated later neighbor. An additional empty bag joins the roots
from disconnected components. The recognizer uses `O(N^3 + M)` time and
`O(N^2)` adjacency storage in this deliberately small profile; it does not
claim the official task's 500,000-vertex scale.

Successful output is a fixed-size little-endian signed-64 word vector:

```text
[K, 2, N,
 size_0, v_00, v_01, v_02, ... size_N, v_N0, v_N1, v_N2,
 child_0, parent_0, ..., child_(N-1), parent_(N-1)]
```

Here `K=N+1`; bags `0..N-1` follow elimination order, bag `N` is empty, and
unused bag slots contain `-1`. Bag and tree-node IDs are zero-based. Each
nonempty bag is joined to its parent; a component root points to the empty
bag. The reported width is always 2, which the task permits, and every bag
contains at most three graph vertices. The output size is `8*(6*N+7)` bytes,
up to 1,592 bytes. Malformed input or a graph without a degree-two elimination
returns `-1`; valid input with null output or insufficient capacity returns
`-2`, without writing.

## Independent checking

The primary oracle uses an adjacency matrix and constructs the deterministic
certificate. The verifier oracle uses bit-set adjacency and independently
checks the emitted certificate's tree structure, edge coverage, bag widths,
and running-intersection property for each graph vertex. Workload fixtures
pin a singleton certificate and exercise paths, cycles, disconnected
components, a maximal 32-vertex 2-tree, malformed graph frames, width-three
rejection, null output, and capacity errors.

## Provenance and rights

The task semantics and limits come from the Apache-2.0 licensed Library
Checker repository: [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/graph/tree_decomposition_width_2/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/tree_decomposition_width_2/info.toml),
and [repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The implementation is a clean-room bounded realization of degree-at-most-two
elimination and reverse-elimination bags; no upstream implementation code is
included. See [RIGHTS.md](RIGHTS.md).

## Files

- Workload: [workload.json](workload.json)
- Primary oracle: [`tree_decomposition_width_2_oracle.py`](../../tree_decomposition_width_2_oracle.py)
- Independent oracle and certificate validator: [`tree_decomposition_width_2_verifier_oracle.py`](../../tree_decomposition_width_2_verifier_oracle.py)
- Static package checker: [verify_workload.py](verify_workload.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/t/tree_decomposition_width_2.c`](../../../c/t/tree_decomposition_width_2.c) |
| C3 | [`c3/t/tree_decomposition_width_2.c3`](../../../c3/t/tree_decomposition_width_2.c3) |
| C++ | [`cpp/t/tree_decomposition_width_2.cpp`](../../../cpp/t/tree_decomposition_width_2.cpp) |
| Elisa | [`elisa/t/tree_decomposition_width_2.elisa`](../../../elisa/t/tree_decomposition_width_2.elisa) |
| Mojo | [`mojo/t/tree_decomposition_width_2.mojo`](../../../mojo/t/tree_decomposition_width_2.mojo) |
| Nim | [`nim/t/tree_decomposition_width_2.nim`](../../../nim/t/tree_decomposition_width_2.nim) |
| Odin | [`odin/t/tree_decomposition_width_2.odin`](../../../odin/t/tree_decomposition_width_2.odin) |
| Rust | [`rust/t/tree_decomposition_width_2.rs`](../../../rust/t/tree_decomposition_width_2.rs) |
| V | [`v/t/tree_decomposition_width_2.v`](../../../v/t/tree_decomposition_width_2.v) |
| Zig | [`zig/t/tree_decomposition_width_2.zig`](../../../zig/t/tree_decomposition_width_2.zig) |
