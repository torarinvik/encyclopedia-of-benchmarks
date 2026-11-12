# Connected labeled graph count

Count connected simple undirected graphs on a fixed labeled vertex set, modulo
998244353. Vertices carry distinct labels, loops and multiple edges are
forbidden, and each possible undirected edge is either present or absent.

## Contract

The exported scalar ABI symbol is `connected_labeled_graph_count`. Input is a
one-element signed 64-bit array `[N]`, with `1<=N<=512`. The result is the
number of connected graphs on those `N` labeled vertices modulo 998244353.
Malformed input, including a null pointer, the wrong array length, or a value
outside the bound, returns `-1`. The largest valid input has one word; every
valid result lies in `[0,998244352]`.

## Algorithms

There are `G_n=2^(n(n-1)/2)` simple labeled graphs in total. For each
disconnected graph, distinguish one vertex and let its connected component
have size `k`. Choosing the other `k-1` component labels, a connected graph on
that component, and an arbitrary graph on the remaining vertices gives

`C_n = G_n - sum(k=1..n-1) binom(n-1,k-1) C_k G_(n-k)`.

The primary ports evaluate this rooted-component recurrence with modular
factorials and powers of two. They take `O(N^2)` time and `O(N)` space.

The independent oracle uses exponential generating functions. If
`A(x)=sum G_n*x^n/n!` counts all graphs, then `log(A(x))` counts connected
graphs. It computes `1/A(x)` by formal-series inversion and extracts the
coefficient of `A'(x)/A(x)`, rather than using the rooted-component recurrence.
It also takes `O(N^2)` time and `O(N)` space.

## Distinctness and provenance

[`graph_enumeration`](../../g/graph_enumeration/README.md) maps adjacency rows
to dense IDs; it does not count graphs. [`graph_coloring`](../../g/graph_coloring/README.md)
counts proper color assignments for a supplied graph, and
[`counting_spanning_trees_undirected`](../counting_spanning_trees_undirected/README.md)
counts spanning trees of one supplied graph. Neither counts the connected
simple graphs on all labeled vertex sets of size `N`.

The algorithm reference is [CP-Algorithms, “Counting labeled graphs”](https://cp-algorithms.com/combinatorics/counting_labeled_graphs.html),
licensed under CC BY-SA 4.0. This package uses only the high-level recurrence
and generating-function relationships. The bounded ABI, fixtures, independent
oracle, and ten ports are clean-room work; no article code or prose was copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../connected_labeled_graph_count_oracle.py), the
[independent oracle](../../connected_labeled_graph_count_verifier_oracle.py),
and the package-local [static inventory checker](../../check_connected_labeled_graph_count_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/connected_labeled_graph_count.c`](../../../c/c/connected_labeled_graph_count.c) |
| C3 | [`c3/c/connected_labeled_graph_count.c3`](../../../c3/c/connected_labeled_graph_count.c3) |
| C++ | [`cpp/c/connected_labeled_graph_count.cpp`](../../../cpp/c/connected_labeled_graph_count.cpp) |
| Elisa | [`elisa/c/connected_labeled_graph_count.elisa`](../../../elisa/c/connected_labeled_graph_count.elisa) |
| Mojo | [`mojo/c/connected_labeled_graph_count.mojo`](../../../mojo/c/connected_labeled_graph_count.mojo) |
| Nim | [`nim/c/connected_labeled_graph_count.nim`](../../../nim/c/connected_labeled_graph_count.nim) |
| Odin | [`odin/c/connected_labeled_graph_count.odin`](../../../odin/c/connected_labeled_graph_count.odin) |
| Rust | [`rust/c/connected_labeled_graph_count.rs`](../../../rust/c/connected_labeled_graph_count.rs) |
| V | [`v/c/connected_labeled_graph_count.v`](../../../v/c/connected_labeled_graph_count.v) |
| Zig | [`zig/c/connected_labeled_graph_count.zig`](../../../zig/c/connected_labeled_graph_count.zig) |
