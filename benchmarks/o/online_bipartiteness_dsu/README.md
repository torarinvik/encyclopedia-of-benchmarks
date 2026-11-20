# Online bipartiteness with a parity DSU

Each inserted undirected edge requires opposite endpoint colors. The DSU
stores xor parity from each node to its parent and a persistent contradiction
flag on each root. Inserting an edge within one component marks it non-bipartite
when both endpoints have the same parity. Merging components combines both
flags and sets the bridge parity so the new edge connects opposite colors.

## Contract

The `i64_array_scalar` input is `[n,q,(opcode,first,second)*q]`, with
`1<=n<=32`, `0<=q<=64`, and exact three-word operation records. Opcode `0`
adds the undirected edge `(first,second)`; self-loops and repeated edges are
allowed. Opcode `1` queries whether the component containing `first` is still
bipartite and requires `second=0`. The result is
`sum((query_ordinal+1)*(answer+1))`, where answers are 1 for bipartite and 0
otherwise. Malformed input returns `-1`.

The DSU processes each operation in `O(alpha(n))` amortized time. The
independent reference rebuilds the current adjacency lists and colors the
queried component with graph traversal.

## Distinction and provenance

The closest local structure, [`unionfind_with_potential`](../../u/unionfind_with_potential/README.md),
stores modular offsets and rejects a contradictory equation without changing
the structure. This profile must retain all inserted edges and remember that
the affected component is no longer bipartite. The static
[`is_graph_bipartite`](../../i/is_graph_bipartite/README.md) and
[`bipartite_graph_dfs`](../../b/bipartite_graph_dfs/README.md) profiles color a
fixed graph rather than answering as edges arrive.

The method comes from CP-Algorithms' [Disjoint Set Union article, parity and
online bipartiteness section](https://cp-algorithms.com/data_structures/disjoint_set_union.html),
published under CC BY-SA 4.0. Its algorithm description is used as a source
idea only. The contract, implementations, references, fixtures, and prose are
independently authored; see [RIGHTS.md](RIGHTS.md). The source-only
[`verify_workload.py`](verify_workload.py) checks inventory and references.
The maximum fixture contains 64 queries of the isolated vertex 0; all answers
are 1 and the weighted checksum is `2 * (1 + ... + 64) = 4,160`.

| Language | Source |
|---|---|
| C | [`c/o/online_bipartiteness_dsu.c`](../../../c/o/online_bipartiteness_dsu.c) |
| C3 | [`c3/o/online_bipartiteness_dsu.c3`](../../../c3/o/online_bipartiteness_dsu.c3) |
| C++ | [`cpp/o/online_bipartiteness_dsu.cpp`](../../../cpp/o/online_bipartiteness_dsu.cpp) |
| Elisa | [`elisa/o/online_bipartiteness_dsu.elisa`](../../../elisa/o/online_bipartiteness_dsu.elisa) |
| Mojo | [`mojo/o/online_bipartiteness_dsu.mojo`](../../../mojo/o/online_bipartiteness_dsu.mojo) |
| Nim | [`nim/o/online_bipartiteness_dsu.nim`](../../../nim/o/online_bipartiteness_dsu.nim) |
| Odin | [`odin/o/online_bipartiteness_dsu.odin`](../../../odin/o/online_bipartiteness_dsu.odin) |
| Rust | [`rust/o/online_bipartiteness_dsu.rs`](../../../rust/o/online_bipartiteness_dsu.rs) |
| V | [`v/o/online_bipartiteness_dsu.v`](../../../v/o/online_bipartiteness_dsu.v) |
| Zig | [`zig/o/online_bipartiteness_dsu.zig`](../../../zig/o/online_bipartiteness_dsu.zig) |
