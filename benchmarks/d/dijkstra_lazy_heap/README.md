# Dijkstra with a lazy binary heap

This profile computes single-source shortest distances in a directed graph
with nonnegative signed-i64 edge weights. It uses indexed adjacency lists and
a binary min-heap of immutable `(distance, vertex)` records. A successful
relaxation pushes a new record instead of updating an existing heap item. On
pop, records whose distance no longer matches the vertex's current label are
stale and are discarded before their outgoing edges are scanned. This
duplicate-entry frontier is materially different from the local [`dijkstra`](../dijkstra/README.md)
profile, which selects the next vertex by a dense scan.

## Contract

The exported `dijkstra_lazy_heap` symbol uses the existing `shortest_path`
ABI:

```c
int64_t dijkstra_lazy_heap(const int64_t *edges,
                           size_t vertices, size_t edge_count, size_t source,
                           int64_t *distances, uint8_t *reachable);
```

`edges` is a flat array of directed triples `(origin,destination,weight)`;
the caller provides valid storage for `3*edge_count` edge words, `vertices`
distances, and `vertices` reachability bytes. Nonempty buffers must be valid,
large enough, and disjoint; a zero-length buffer may be null. The profile
bounds `vertices<=64` and `edge_count<=256`. If `vertices==0`, success requires
`edge_count==0` and `source==0`. Otherwise `source` and every endpoint must
be in `[0,vertices)`. Every edge weight must be nonnegative, including edges
unreachable from the source. The function checks graph size, then the source,
then each edge in input order; for each edge, endpoints are checked before
its weight.

| Return | Meaning |
|---:|---|
| `0` | Success |
| `-2` | Adding an edge weight to a popped reachable distance exceeds `INT64_MAX` |
| `-3` | Invalid graph size, empty-graph shape, source, or endpoint |
| `-4` | Negative edge weight |

On success, `reachable[v]` is `1` exactly for vertices reachable from the
source. Reachable distances are exact; unreachable distance slots are zero.
The reachability flag allows `INT64_MAX` to remain a valid finite distance.
Output buffers are unspecified after an error.

Heap keys are ordered lexicographically by `(distance, vertex)`, and edges
within each adjacency list retain input order. Relaxations push only on a
strict improvement, making processing deterministic even for ties. The stale
record test occurs before overflow checks and edge scans. For each live popped
vertex, every outgoing edge is examined once; there are at most `E+1` heap
records, including the source. The running time is `O(V + E log(E+1))` and
the fixed arrays reserve 8,192 bytes of workspace.

## Provenance

The algorithm follows CP-Algorithms' [Dijkstra on sparse graphs](https://cp-algorithms.com/graph/dijkstra_sparse.html),
which describes a priority queue without decrease-key: push a new distance
pair after each strict improvement and skip popped pairs that are no longer
current. The source page is CC BY-SA 4.0. Only the algorithm idea was
consulted; this contract, workload, oracles, and all ports are independently
authored. The independent Bellman–Ford oracle uses arbitrary-precision labels
and checks overflow after computing shortest distances, rather than using a
heap or stale-entry filtering.

See [workload.json](workload.json), [primary_oracle.py](primary_oracle.py),
[independent_oracle.py](independent_oracle.py), [RIGHTS.md](RIGHTS.md), and
[check_inventory.py](check_inventory.py). The dedicated all-language verifier
is [verify_dijkstra_lazy_heap.py](../../verify_dijkstra_lazy_heap.py); it was
added as source but has not been run.

| Language | Port |
|---|---|
| C | [c/d/dijkstra_lazy_heap.c](../../../c/d/dijkstra_lazy_heap.c) |
| C3 | [c3/d/dijkstra_lazy_heap.c3](../../../c3/d/dijkstra_lazy_heap.c3) |
| C++ | [cpp/d/dijkstra_lazy_heap.cpp](../../../cpp/d/dijkstra_lazy_heap.cpp) |
| Elisa | [elisa/d/dijkstra_lazy_heap.elisa](../../../elisa/d/dijkstra_lazy_heap.elisa) |
| Mojo | [mojo/d/dijkstra_lazy_heap.mojo](../../../mojo/d/dijkstra_lazy_heap.mojo) |
| Nim | [nim/d/dijkstra_lazy_heap.nim](../../../nim/d/dijkstra_lazy_heap.nim) |
| Odin | [odin/d/dijkstra_lazy_heap.odin](../../../odin/d/dijkstra_lazy_heap.odin) |
| Rust | [rust/d/dijkstra_lazy_heap.rs](../../../rust/d/dijkstra_lazy_heap.rs) |
| V | [v/d/dijkstra_lazy_heap.v](../../../v/d/dijkstra_lazy_heap.v) |
| Zig | [zig/d/dijkstra_lazy_heap.zig](../../../zig/d/dijkstra_lazy_heap.zig) |
