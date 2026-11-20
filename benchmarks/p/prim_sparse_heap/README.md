# Prim with an indexed sparse frontier

This profile computes the minimum spanning tree weight of an undirected graph
using adjacency lists and an indexed binary min-heap. It starts at vertex 0,
stores one candidate key for each vertex outside the tree, extracts the least
`(best edge weight, vertex)` pair, and decreases a vertex key when a cheaper
crossing edge is found. The frontier therefore performs ordered extraction
and decrease-key operations, unlike the local [`prim`](../prim/README.md)
profile's dense O(V) scan for each selected vertex.

## Contract

The exported `prim_sparse_heap` symbol uses the `i64_array_scalar` ABI. The
packed input is `[vertex_count, edge_count, u_0, v_0, weight_0, ...]`, with
zero-based vertices and signed-i64 words. There are at most 64 vertices and
4,096 input edge records. Every endpoint must be in `[0, vertex_count)` and
every edge weight in `[0, 2^31-1]`. Edges are undirected. Self-loops have no
effect. Parallel edges behave as if only their minimum weight were retained;
the adjacency list may keep them and the frontier's strict decrease handles
the minimum directly.

| Return | Meaning |
|---:|---|
| `0` or greater | Minimum spanning-tree total weight; an empty graph or one vertex returns `0` |
| `-1` | The nonempty graph is disconnected |
| `-2` | Malformed length, bounds, endpoint, or edge weight |

The tree is rooted at vertex 0. Equal frontier weights are ordered by vertex
ID; an equal candidate does not replace the existing key. The total fits in
signed i64 because at most 63 selected edges each weigh at most `2^31-1`.
Input errors are validated before the heap traversal.

The implementation stores up to 8,192 directed adjacency incidences, plus
vertex keys and heap positions. A fixed workspace cap of 200,704 bytes covers
the language ports' 64-bit index arrays, alignment, and all bounded records.
Adjacency construction is O(V+E); heap extractions and strict key decreases
give O((V+E) log V) time. The Kruskal reference is structurally independent.

## Provenance

The sparse-frontier method follows CP-Algorithms' [Prim's minimum spanning
tree article](https://cp-algorithms.com/graph/mst_prim.html), especially its
sparse-graph section: keep the best crossing edge per unselected vertex,
extract the smallest key from an ordered frontier, and update keys from the
newly selected vertex. The article is CC BY-SA 4.0. Only the algorithm idea
was consulted; the benchmark contract, workload, references, and ports were
authored independently.

See [workload.json](workload.json), [primary_oracle.py](primary_oracle.py),
[independent_oracle.py](independent_oracle.py), [RIGHTS.md](RIGHTS.md),
[verify_workload.py](verify_workload.py), [check_inventory.py](check_inventory.py),
and [INVENTORY.md](INVENTORY.md). The dedicated all-language suite verifier is
[verify_prim_sparse_heap.py](../../verify_prim_sparse_heap.py); the profile is
registered in the shared `i64_array_scalar` runner and verifier. Neither the
dedicated verifier nor the shared suite has been run.

| Language | Port |
|---|---|
| C | [c/p/prim_sparse_heap.c](../../../c/p/prim_sparse_heap.c) |
| C3 | [c3/p/prim_sparse_heap.c3](../../../c3/p/prim_sparse_heap.c3) |
| C++ | [cpp/p/prim_sparse_heap.cpp](../../../cpp/p/prim_sparse_heap.cpp) |
| Elisa | [elisa/p/prim_sparse_heap.elisa](../../../elisa/p/prim_sparse_heap.elisa) |
| Mojo | [mojo/p/prim_sparse_heap.mojo](../../../mojo/p/prim_sparse_heap.mojo) |
| Nim | [nim/p/prim_sparse_heap.nim](../../../nim/p/prim_sparse_heap.nim) |
| Odin | [odin/p/prim_sparse_heap.odin](../../../odin/p/prim_sparse_heap.odin) |
| Rust | [rust/p/prim_sparse_heap.rs](../../../rust/p/prim_sparse_heap.rs) |
| V | [v/p/prim_sparse_heap.v](../../../v/p/prim_sparse_heap.v) |
| Zig | [zig/p/prim_sparse_heap.zig](../../../zig/p/prim_sparse_heap.zig) |
