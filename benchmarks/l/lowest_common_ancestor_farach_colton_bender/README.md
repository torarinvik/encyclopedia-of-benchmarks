# Lowest Common Ancestor by Farach–Colton–Bender

This package answers a batch of lowest-common-ancestor queries on a rooted
view of an undirected tree. It uses an Euler tour and the ±1 depth property to
answer range-minimum queries with microblock signatures and a macroblock
sparse table. This is distinct from binary lifting's ancestor table and
Tarjan's offline disjoint-set traversal.

## Contract

The exported symbol is
`lowest_common_ancestor_farach_colton_bender(const int64_t *input,
size_t length, uint8_t *output, size_t capacity)` with ABI
`i64_array_bytes_output`.

Input is `[node_count, root_id, edge_count, query_count, edge_pairs...,
query_pairs...]`. Vertex IDs are zero-based. `1 <= node_count <= 256`,
`edge_count == node_count - 1`, and `0 <= query_count <= 1024`. The edges must
form a connected acyclic tree. The root and all query endpoints must be valid
vertex IDs. The maximum input length is 2,562 signed 64-bit words.

Output contains one unsigned byte per query, in query order. Each byte is the
LCA vertex ID, which fits because the maximum vertex ID is 255. A successful
call returns the number of bytes written. Invalid framing, edges, tree shape,
or query endpoints return `-1`; null or undersized output for a nonempty batch
returns `-2`. A zero-query batch returns zero and accepts a null output. The
ports stage all answers before writing output.

## RMQ method

An iterative DFS records the Euler tour, Euler depths, each vertex's first
occurrence, and the rooted parent/depth arrays. Adjacent Euler depths differ
by exactly one. For Euler length `L`, the microblock width is
`max(1, floor(floor(log2(L))/2))`; it is at most four for this profile. Each
microblock is encoded by its up/down signature, and a small table stores the
minimum offset for every in-block interval. A sparse table over microblock
minima answers the complete blocks between the two partial endpoint blocks.
The Euler-tour minimum between the two first occurrences gives the LCA.

The microblock signature tables use `O(sqrt(L) log^3 L)` bounded setup work;
the macroblock sparse table and the rest of the preprocessing use `O(L)`
space and time. Each query takes `O(1)` time. The primary oracle instead
climbs rooted parent links. The independent verifier builds the rooted view
with BFS and finds each answer by intersecting explicit ancestor sets.

## Source and rights

The method follows the algorithm description in CP-Algorithms'
[Farach–Colton–Bender LCA article](https://cp-algorithms.com/graph/lca_farachcoltonbender.html).
The article is CC BY-SA 4.0. These files are clean-room implementations based
on the algorithm description; no source code is copied. See
[RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/l/lowest_common_ancestor_farach_colton_bender.c`](../../../c/l/lowest_common_ancestor_farach_colton_bender.c) |
| C3 | [`c3/l/lowest_common_ancestor_farach_colton_bender.c3`](../../../c3/l/lowest_common_ancestor_farach_colton_bender.c3) |
| C++ | [`cpp/l/lowest_common_ancestor_farach_colton_bender.cpp`](../../../cpp/l/lowest_common_ancestor_farach_colton_bender.cpp) |
| Elisa | [`elisa/l/lowest_common_ancestor_farach_colton_bender.elisa`](../../../elisa/l/lowest_common_ancestor_farach_colton_bender.elisa) |
| Mojo | [`mojo/l/lowest_common_ancestor_farach_colton_bender.mojo`](../../../mojo/l/lowest_common_ancestor_farach_colton_bender.mojo) |
| Nim | [`nim/l/lowest_common_ancestor_farach_colton_bender.nim`](../../../nim/l/lowest_common_ancestor_farach_colton_bender.nim) |
| Odin | [`odin/l/lowest_common_ancestor_farach_colton_bender.odin`](../../../odin/l/lowest_common_ancestor_farach_colton_bender.odin) |
| Rust | [`rust/l/lowest_common_ancestor_farach_colton_bender.rs`](../../../rust/l/lowest_common_ancestor_farach_colton_bender.rs) |
| V | [`v/l/lowest_common_ancestor_farach_colton_bender.v`](../../../v/l/lowest_common_ancestor_farach_colton_bender.v) |
| Zig | [`zig/l/lowest_common_ancestor_farach_colton_bender.zig`](../../../zig/l/lowest_common_ancestor_farach_colton_bender.zig) |

The package fixtures are in [`workload.json`](workload.json). Its parent-climb
oracle and independent verifier are
[`lowest_common_ancestor_farach_colton_bender_oracle.py`](../../lowest_common_ancestor_farach_colton_bender_oracle.py)
and
[`lowest_common_ancestor_farach_colton_bender_verifier_oracle.py`](../../lowest_common_ancestor_farach_colton_bender_verifier_oracle.py).
