# Decremental connectivity

Maintain connectivity in an undirected forest while edges are deleted. The trace includes connectivity queries before and after deletions. This is a dynamic data-structure workload, distinct from computing connected components once or answering connectivity with a fresh DSU.

## Contract

- ABI: signed i64 array to signed i64 scalar.
- Input is `[n, m, edge_u_0, edge_v_0, ..., q, op_0, u_0, v_0, ...]`. `1 <= n <= 32`, `0 <= m <= n-1`, and `0 <= q <= 128`.
- Edges are zero-based undirected endpoint pairs. The initial graph must be a simple forest; duplicate edges, self-loops, and cycles are invalid. The Rust source examples use self-membership entries as root-parent markers in adjacency sets; these are representation sentinels, so the portable input omits them.
- Each operation is `[op,u,v]`: `op=0` deletes an existing edge, and `op=1` asks whether `u` and `v` are connected. Deleting a missing edge or using an invalid vertex is invalid.
- Components receive labels during initial traversal. After deletion, the implementation finds both resulting sides, relabels the smaller side with a new component id (ties select the side rooted at the lower endpoint), and keeps later queries constant-time. This bounded contract deterministically preserves the source's small-side relabel strategy; it uses complete side walks to choose the smaller part.
- The result is the signed i64 view of FNV-1a-64 over one byte per query answer (`0` or `1`). Invalid input returns `-1`.

The contract follows the pinned [Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/decremental_connectivity.rs), which rejects non-forests, labels initial components, deletes existing edges, and DFS-relabels the smaller component. Its API panics for invalid deletions; the benchmark defines an invalid-input sentinel for portable validation.

The workload includes empty traces, disconnected forests, branch cuts, repeated connectivity queries, and invalid cycles, loops, duplicate edges, and deletions.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/decremental_connectivity.c`](../../../c/d/decremental_connectivity.c) |
| C3 | [`c3/d/decremental_connectivity.c3`](../../../c3/d/decremental_connectivity.c3) |
| C++ | [`cpp/d/decremental_connectivity.cpp`](../../../cpp/d/decremental_connectivity.cpp) |
| Elisa | [`elisa/d/decremental_connectivity.elisa`](../../../elisa/d/decremental_connectivity.elisa) |
| Nim | [`nim/d/decremental_connectivity.nim`](../../../nim/d/decremental_connectivity.nim) |
| Odin | [`odin/d/decremental_connectivity.odin`](../../../odin/d/decremental_connectivity.odin) |
| Rust | [`rust/d/decremental_connectivity.rs`](../../../rust/d/decremental_connectivity.rs) |
| V | [`v/d/decremental_connectivity.v`](../../../v/d/decremental_connectivity.v) |
| Zig | [`zig/d/decremental_connectivity.zig`](../../../zig/d/decremental_connectivity.zig) |
