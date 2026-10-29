# Counting Spanning Trees (Directed)

Count outward spanning arborescences rooted at a specified vertex in a small
directed multigraph. The task is based on the [Library Checker directed
spanning-tree specification](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_spanning_tree_directed/task.md).
Only the algorithm task is used as a reference; the implementations and oracle
here are independently written.

## Contract

The `i64_array_bytes_output` input is `[n, m, r, (u, v)*m]`. Vertices use
zero-based IDs, `1 <= n <= 6`, `0 <= m <= 12`, and `0 <= r < n`. Each arc is
directed from `u` to `v`. Parallel arcs are distinct choices and are counted
with their multiplicity. Self-loops are valid input but cannot contribute to
an outward spanning arborescence. The result is the number of arborescences
modulo `998244353`, encoded as an unsigned 64-bit integer in eight
little-endian bytes. Every vertex must be reachable from `r`; each other
vertex has one selected incoming arc. An unreachable graph has count zero.
Invalid input returns `-1`; a null output pointer or capacity below eight bytes
returns `-2`. Input validation takes precedence over output errors, and
failures write no bytes.

## Algorithm and bounds

For each arc `u -> v`, the in-degree Laplacian adds one at `(v, v)` and
subtracts one at `(v, u)`. Self-loop contributions cancel. Delete the row and
column for `r`; the directed Matrix-Tree theorem says the remaining cofactor
determinant counts outward arborescences rooted at `r`. Modular Gaussian
elimination computes the determinant in the prime field, using Fermat
inverses for nonzero pivots. Parallel arcs add separately to the matrix.

The measured ports use `O(n^3 + m)` time and `O(n^2)` space. With the stated
limits, modular products fit in signed 64-bit intermediates. The independent
oracle enumerates edge-index subsets of size `n-1`, checks their indegrees,
then traverses the selected arcs from the root; parallel arcs therefore
remain separate choices. Its exhaustive subset method is bounded by
`C(m, n-1)` subsets for this workload.

See [`workload.json`](workload.json), the independent
[edge-subset enumeration oracle](../../counting_spanning_trees_directed_oracle.py),
and the [static fixture/source checker](../../counting_spanning_trees_directed_verifier.py).
No implementation has been executed or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/counting_spanning_trees_directed.c`](../../../c/c/counting_spanning_trees_directed.c) |
| C3 | [`c3/c/counting_spanning_trees_directed.c3`](../../../c3/c/counting_spanning_trees_directed.c3) |
| C++ | [`cpp/c/counting_spanning_trees_directed.cpp`](../../../cpp/c/counting_spanning_trees_directed.cpp) |
| Elisa | [`elisa/c/counting_spanning_trees_directed.elisa`](../../../elisa/c/counting_spanning_trees_directed.elisa) |
| Nim | [`nim/c/counting_spanning_trees_directed.nim`](../../../nim/c/counting_spanning_trees_directed.nim) |
| Odin | [`odin/c/counting_spanning_trees_directed.odin`](../../../odin/c/counting_spanning_trees_directed.odin) |
| Rust | [`rust/c/counting_spanning_trees_directed.rs`](../../../rust/c/counting_spanning_trees_directed.rs) |
| V | [`v/c/counting_spanning_trees_directed.v`](../../../v/c/counting_spanning_trees_directed.v) |
| Zig | [`zig/c/counting_spanning_trees_directed.zig`](../../../zig/c/counting_spanning_trees_directed.zig) |
