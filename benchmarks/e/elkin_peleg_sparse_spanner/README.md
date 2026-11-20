# Elkin–Peleg sparse graph spanner

This package implements a deterministic bounded profile of Elkin and Peleg's
`Sp Cons` construction for simple, unweighted, undirected graphs. It builds a
ground partition with `Down Part`, adds BFS trees for each cluster shell, then
uses one superclustering level and a final nearby-cluster path pass. The result
is reported as one retention byte per input edge.

## Contract

The ABI is `i64_array_bytes_output`, symbol `elkin_peleg_sparse_spanner`.
Input is `[n,m,(u,v)*m]`, with `1<=n<=20`, `0<=m<=190`, exact length
`2+2*m`, normalized endpoints `0<=u<v<n`, and no duplicate edges. Graphs may
be disconnected. Output contains exactly `m` bytes in input-edge order (`1`
means the edge is included in the constructed subgraph). Invalid input returns
`-1`; null output or capacity below `m` returns `-2` without writes. The
maximum parseable input is 383 signed 64-bit words and the output cap is 190
bytes.

The fixed theorem parameters are `kappa=4`, `epsilon=1/2`, `J=2`, and
`upsilon=64`. Thus `t_1=3/8`, `t_2=1/8`, `delta=(8,64)`, and the only
intermediate threshold is `sigma_1=ceil(n^(1/4))`. The ceiling is exactly the
integer equivalent of the paper's test `cluster_count >= n^(1/4)`. Down Part's
growth test uses the exact integer comparison `|shell|^4 >= n*|S|^4`; it does
not use floating-point arithmetic. Growth also stops when the shell adds no
vertices; this finite-profile guard handles the one-vertex graph, where the
unchanged singleton otherwise satisfies the multiplicative test forever. The
first SC call uses distance `2*delta_1`
(`16`), and the final path pass uses `2*delta_2` (`128`). The radius bands are
`tau_1=[1/2,3/2)` and `tau_2=[3/2,4)`, so the first contains radius-1 ground
clusters and the final band contains radii 2 and 3.

All unspecified source choices are fixed for repeatable output: choose the
smallest uncovered vertex, traverse ascending neighbors for BFS, choose an
eligible SC center by `(center ID, sorted member IDs)`, and choose the
lexicographically smallest vertex sequence among equal-length connector paths.
The construction emits the union of shell BFS trees, merged-cluster trees and
connector paths, and the SC/final close-pair connector paths. Disconnected
cluster pairs have infinite distance and are never joined.

The paper's parameter theorem targets a `(3/2,64)`-spanner with
`O(64*n^(5/4))` edges for this parameter choice. The package reports the exact
bounded trace; its workload does not claim the asymptotic edge bound as a
measured property. The straightforward paper runtime specializes to
`O(m*n^(3/4))`; this implementation uses bounded BFS scans and has no separate
asymptotic runtime claim.

The primary reference uses FIFO BFS with neighbors visited in ascending vertex
order; this visits equal-length paths in lexicographic sequence order. For a
connector between two clusters it considers each start vertex in ascending
order and compares all reachable target paths by length, then vertex sequence.
The independent reference uses a Boolean adjacency matrix and
Floyd–Warshall distances. It reconstructs each canonical path by repeatedly
choosing the smallest adjacent vertex that reduces the remaining distance by
one, and compares the same start/target candidates. Its cluster trees are the
union of these canonical root-to-vertex paths in the induced cluster or shell.
This structurally different reference reproduces the exact byte output, not
merely any valid spanner. The [workload](workload.json) includes edge,
triangle, complete-graph, radius-2, superclustering, disconnected, framing,
null-output, and capacity cases. The static inventory is
[`verify_workload.py`](verify_workload.py).

## Sources and rights

The book chapter [“Sparse Graph Spanners,” DOI 387](https://doi.org/10.1007/978-1-4939-2864-4_387)
states the `(1+epsilon,beta)` spanner problem and summarizes the Elkin–Peleg
result. The procedure comes from Elkin and Peleg, [“(1 + ε, β)-Spanner
Constructions for General Graphs,” SIAM Journal on Computing 33(3), 608–631
(2004)](https://doi.org/10.1137/S0097539701393384), Sections 2.1–2.3 and the
parameter analysis in Section 3. This package uses source descriptions for
algorithm ideas only; it contains no copied source code, pseudocode, figures,
problem prose, or tests. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/e/elkin_peleg_sparse_spanner.c`](../../../c/e/elkin_peleg_sparse_spanner.c) |
| C3 | [`c3/e/elkin_peleg_sparse_spanner.c3`](../../../c3/e/elkin_peleg_sparse_spanner.c3) |
| C++ | [`cpp/e/elkin_peleg_sparse_spanner.cpp`](../../../cpp/e/elkin_peleg_sparse_spanner.cpp) |
| Elisa | [`elisa/e/elkin_peleg_sparse_spanner.elisa`](../../../elisa/e/elkin_peleg_sparse_spanner.elisa) |
| Mojo | [`mojo/e/elkin_peleg_sparse_spanner.mojo`](../../../mojo/e/elkin_peleg_sparse_spanner.mojo) |
| Nim | [`nim/e/elkin_peleg_sparse_spanner.nim`](../../../nim/e/elkin_peleg_sparse_spanner.nim) |
| Odin | [`odin/e/elkin_peleg_sparse_spanner.odin`](../../../odin/e/elkin_peleg_sparse_spanner.odin) |
| Rust | [`rust/e/elkin_peleg_sparse_spanner.rs`](../../../rust/e/elkin_peleg_sparse_spanner.rs) |
| V | [`v/e/elkin_peleg_sparse_spanner.v`](../../../v/e/elkin_peleg_sparse_spanner.v) |
| Zig | [`zig/e/elkin_peleg_sparse_spanner.zig`](../../../zig/e/elkin_peleg_sparse_spanner.zig) |
