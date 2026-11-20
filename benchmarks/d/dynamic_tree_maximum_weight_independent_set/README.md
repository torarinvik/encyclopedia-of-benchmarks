# Dynamic tree maximum-weight independent set

Maintain the maximum-weight independent-set value of a fixed tree as vertex
weights are replaced. An independent set contains no adjacent pair of
vertices. The tree is rooted at vertex zero during preprocessing; every update
replaces one vertex's weight, and produces the optimum for the updated tree.

## Bounded input and output

The exported entry point is
`dynamic_tree_maximum_weight_independent_set` with the
`i64_array_bytes_output` ABI. Input is
`[N,Q,weights[0..N-1],(u,v) for each edge,(vertex,new_weight) for each update]`.
The tree has `1 <= N <= 64`, `0 <= Q <= 64`, and all weights lie in
`0..=1,000,000`. The `N-1` undirected edges must form a tree. Every updated
vertex and replacement weight must be in range. Input length is exactly
`3*N + 2*Q`, at most 320 signed 64-bit words.

Each replacement emits the new global optimum as a signed 64-bit integer in
little-endian order. At most 512 output bytes are written. Malformed input or
topology returns `-1`; null or insufficient output storage for nonempty output
returns `-2`, with no output written. A valid zero-update call returns zero
bytes and accepts a null output pointer. The declared fixed working storage
bound is 32 KiB.

## Dynamic programming kernel

For each vertex `u`, the static recurrence has two values: `skip[u]`, the best
value when `u` is omitted, and `take[u]`, the best value when it is selected.
The updates use the OI Wiki dynamic-DP method: heavy-light decomposition turns
each heavy chain into an ordered product of 2-by-2 matrices over max-plus
arithmetic. A segment tree stores these products. Replacing a weight changes
one matrix; if a chain's summary changes, its parent light edge adjusts the
parent matrix and propagation continues toward the root. Each update takes
`O(log^2 N)` matrix operations. The ports use a bounded adjacency table for
topology validation and HLD preprocessing, so preprocessing takes `O(N^2)` and
total storage is `O(N^2)`; the dynamic matrix/segment-tree state itself is
`O(N)`.

This is distinct from the one-shot
[`tree_weighted_vertex_cover`](../../t/tree_weighted_vertex_cover/README.md)
profile. Its complement yields the static maximum-weight independent-set
value, but it does not maintain updates or HLD matrix products. It is also
distinct from generic dynamic-tree link-cut and top-tree profiles, which
maintain different aggregates.

The primary reference implements the HLD/max-plus kernel. The independent
oracle replays the ordinary two-state tree DP from scratch after every update.
Fixtures cover single-vertex trees, paths, stars, update propagation, malformed
topologies, and output-capacity behavior. No reference, port, or fixture has
been executed. The package-local [static inventory checker](verify_workload.py)
records the ten source paths and checks fixture metadata against both
references; it has not been run.

## Source and ports

OI Wiki's [Dynamic DP chapter](https://en.oi-wiki.org/dp/dynamic/) describes
the point-update maximum-weight independent-set method using HLD and max-plus
matrices. The article's algorithm description is used as mathematical
provenance only; this package's contract, implementations, references, and
fixtures are independently authored. See [RIGHTS.md](RIGHTS.md).

| Language | Source |
|---|---|
| C | [`c/d/dynamic_tree_maximum_weight_independent_set.c`](../../../c/d/dynamic_tree_maximum_weight_independent_set.c) |
| C3 | [`c3/d/dynamic_tree_maximum_weight_independent_set.c3`](../../../c3/d/dynamic_tree_maximum_weight_independent_set.c3) |
| C++ | [`cpp/d/dynamic_tree_maximum_weight_independent_set.cpp`](../../../cpp/d/dynamic_tree_maximum_weight_independent_set.cpp) |
| Elisa | [`elisa/d/dynamic_tree_maximum_weight_independent_set.elisa`](../../../elisa/d/dynamic_tree_maximum_weight_independent_set.elisa) |
| Mojo | [`mojo/d/dynamic_tree_maximum_weight_independent_set.mojo`](../../../mojo/d/dynamic_tree_maximum_weight_independent_set.mojo) |
| Nim | [`nim/d/dynamic_tree_maximum_weight_independent_set.nim`](../../../nim/d/dynamic_tree_maximum_weight_independent_set.nim) |
| Odin | [`odin/d/dynamic_tree_maximum_weight_independent_set.odin`](../../../odin/d/dynamic_tree_maximum_weight_independent_set.odin) |
| Rust | [`rust/d/dynamic_tree_maximum_weight_independent_set.rs`](../../../rust/d/dynamic_tree_maximum_weight_independent_set.rs) |
| V | [`v/d/dynamic_tree_maximum_weight_independent_set.v`](../../../v/d/dynamic_tree_maximum_weight_independent_set.v) |
| Zig | [`zig/d/dynamic_tree_maximum_weight_independent_set.zig`](../../../zig/d/dynamic_tree_maximum_weight_independent_set.zig) |
