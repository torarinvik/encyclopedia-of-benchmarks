# Kahn topological sorting

This package ports the pinned Go Kahn algorithm for directed acyclic graphs. Duplicate directed edges are ignored, as in the source graph structure. The Go source iterates neighbor maps, so valid order contents may vary; the benchmark compares whether all vertices are processed.

## Contract

Input is `[vertex_count, edge_count, from_0, to_0, ...]`, with 0..32 vertices, 0..128 edge records, exact packed length, and vertex IDs in `0..vertex_count-1`. Output is the vertex count for a DAG and -1 if a cycle prevents processing every vertex. Invalid input returns -2. The empty graph returns zero.

See the [workload](workload.json), [independent oracle](../../kahn_oracle.py), and pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/kahn.go).

| Language | Port |
|---|---|
| C | [`c/k/kahn.c`](../../../c/k/kahn.c) |
| C3 | [`c3/k/kahn.c3`](../../../c3/k/kahn.c3) |
| C++ | [`cpp/k/kahn.cpp`](../../../cpp/k/kahn.cpp) |
| Elisa | [`elisa/k/kahn.elisa`](../../../elisa/k/kahn.elisa) |
| Nim | [`nim/k/kahn.nim`](../../../nim/k/kahn.nim) |
| Odin | [`odin/k/kahn.odin`](../../../odin/k/kahn.odin) |
| Rust | [`rust/k/kahn.rs`](../../../rust/k/kahn.rs) |
| V | [`v/k/kahn.v`](../../../v/k/kahn.v) |
| Zig | [`zig/k/kahn.zig`](../../../zig/k/kahn.zig) |
