# Counting Spanning Trees (Undirected)

Count the spanning trees of a simple undirected graph with at most seven
vertices. The task name follows the [Library Checker problem index](https://judge.yosupo.jp/).
The algorithm uses [Kirchhoff's Matrix-Tree theorem](https://en.wikipedia.org/wiki/Kirchhoff%27s_theorem):
the spanning-tree count is the determinant of any cofactor of the graph's
Laplacian matrix.

## Contract

The `i64_array_bytes_output` input is `[n, m, (u, v)*m]`, with zero-based
vertex IDs, `1 <= n <= 7`, and `0 <= m <= 21`. The edge list describes a simple
undirected graph. Self-loops, repeated undirected edges, out-of-range endpoints,
and any length other than `2 + 2*m` are invalid. The result is the spanning-tree
count modulo `1,000,000,007`, encoded as one unsigned 64-bit integer in eight
little-endian bytes. The one-vertex graph with no edges has one spanning tree;
a disconnected graph has count zero. Invalid input returns `-1`; a null output
pointer or capacity below eight bytes returns `-2`. Validation errors take
precedence over output errors, and failures write no bytes.

## Algorithm and bounds

For each edge, construct the Laplacian by adding one to both endpoint degrees
and subtracting one in the corresponding off-diagonal entries. Delete the row
and column for the final vertex. Modular Gaussian elimination computes the
cofactor determinant; row swaps change the determinant sign, and each nonzero
pivot is inverted with Fermat's little theorem in the prime field. A zero pivot
column means the determinant is zero, as for a disconnected graph.

The bounded ports use `O(n^3 + m)` time and `O(n^2)` space. Every multiplication
of two reduced residues fits in a signed 64-bit intermediate. The output is
reduced modulo `1,000,000,007` before encoding.

## Provenance and independent oracle

The official Library Checker index supplies the problem taxonomy and name; no
submission code or problem text was copied. All nine implementations are
independently written around the Matrix-Tree theorem. The package oracle uses a
different method: it enumerates every `(n-1)`-edge subset and checks for cycles
and connectivity with disjoint-set union. The bounded fixtures cover the
singleton, a tree, a cycle, complete graphs, a disconnected graph, malformed
bounds and edges, output errors, and null input.

See [`workload.json`](workload.json), the subset-enumeration oracle at
[`benchmarks/counting_spanning_trees_undirected_oracle.py`](../../counting_spanning_trees_undirected_oracle.py),
and the fixture checker at
[`benchmarks/counting_spanning_trees_undirected_verifier.py`](../../counting_spanning_trees_undirected_verifier.py).
The language ports and oracle have not been executed or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/counting_spanning_trees_undirected.c`](../../../c/c/counting_spanning_trees_undirected.c) |
| C3 | [`c3/c/counting_spanning_trees_undirected.c3`](../../../c3/c/counting_spanning_trees_undirected.c3) |
| C++ | [`cpp/c/counting_spanning_trees_undirected.cpp`](../../../cpp/c/counting_spanning_trees_undirected.cpp) |
| Elisa | [`elisa/c/counting_spanning_trees_undirected.elisa`](../../../elisa/c/counting_spanning_trees_undirected.elisa) |
| Nim | [`nim/c/counting_spanning_trees_undirected.nim`](../../../nim/c/counting_spanning_trees_undirected.nim) |
| Odin | [`odin/c/counting_spanning_trees_undirected.odin`](../../../odin/c/counting_spanning_trees_undirected.odin) |
| Rust | [`rust/c/counting_spanning_trees_undirected.rs`](../../../rust/c/counting_spanning_trees_undirected.rs) |
| V | [`v/c/counting_spanning_trees_undirected.v`](../../../v/c/counting_spanning_trees_undirected.v) |
| Zig | [`zig/c/counting_spanning_trees_undirected.zig`](../../../zig/c/counting_spanning_trees_undirected.zig) |
