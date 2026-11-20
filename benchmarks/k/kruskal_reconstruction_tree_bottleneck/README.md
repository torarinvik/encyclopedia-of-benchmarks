# Kruskal reconstruction tree bottleneck queries

Answer undirected minimax path queries by building a Kruskal reconstruction
forest and querying lowest common ancestors. During nondecreasing edge order,
each edge that joins two components creates an internal node labeled with that
edge's weight and gives it the two component roots as children. For distinct
connected vertices, the LCA label is the least possible maximum edge weight
along a path between them. This adds pair-query semantics to the local
[`kruskal`](../kruskal/README.md) minimum spanning tree total-weight profile.

## Contract

Input is `[n,m,q,(u,v,w)*m,(s,d)*q]`: an undirected graph followed by query
pairs. Bounds are `1<=n<=8`, `0<=m<=16`, `1<=q<=8`, endpoints in `0..n-1`,
and weights in `0..1,000,000`. Loops and parallel edges are accepted; loops
do not create reconstruction nodes. A query on the same vertex returns zero,
a disconnected pair returns `-1`, and every other query returns the minimum
over paths of their maximum edge weight. The scalar result is
`sum((i+1)*(answer_i+2))`, where `i` is the zero-based query position. The
maximum valid input has 67 i64 values; a 68-value frame is parseable but
invalid. Scratch state is bounded to 4,096 bytes.

Edges are sorted by `(weight, original index)`, then DSU merges build at most
`2n-1` reconstruction nodes. Binary lifting answers each LCA query. The
primary method costs `O(m log m + n log n + q log n)`; the independent
Floyd–Warshall reference uses `O(n^3+m)` time and computes minimax distances
directly.

The merge-tree structure and bottleneck/LCA identity follow the [OI Wiki
minimum-spanning-tree chapter](https://oi-wiki.org/graph/mst/#kruskal-%E9%87%8D%E6%9E%84%E6%A0%91); the
Kruskal cut rule is also reviewed in Carnegie Mellon's [algorithm-design
lecture notes](https://www.cs.cmu.edu/~yangp/15-451/lecture12.pdf). Only
algorithm ideas were consulted. The contract, fixtures, references, and ports
are independently authored.

| Language | Port |
|---|---|
| C | [c/k/kruskal_reconstruction_tree_bottleneck.c](../../../c/k/kruskal_reconstruction_tree_bottleneck.c) |
| C3 | [c3/k/kruskal_reconstruction_tree_bottleneck.c3](../../../c3/k/kruskal_reconstruction_tree_bottleneck.c3) |
| C++ | [cpp/k/kruskal_reconstruction_tree_bottleneck.cpp](../../../cpp/k/kruskal_reconstruction_tree_bottleneck.cpp) |
| Elisa | [elisa/k/kruskal_reconstruction_tree_bottleneck.elisa](../../../elisa/k/kruskal_reconstruction_tree_bottleneck.elisa) |
| Mojo | [mojo/k/kruskal_reconstruction_tree_bottleneck.mojo](../../../mojo/k/kruskal_reconstruction_tree_bottleneck.mojo) |
| Nim | [nim/k/kruskal_reconstruction_tree_bottleneck.nim](../../../nim/k/kruskal_reconstruction_tree_bottleneck.nim) |
| Odin | [odin/k/kruskal_reconstruction_tree_bottleneck.odin](../../../odin/k/kruskal_reconstruction_tree_bottleneck.odin) |
| Rust | [rust/k/kruskal_reconstruction_tree_bottleneck.rs](../../../rust/k/kruskal_reconstruction_tree_bottleneck.rs) |
| V | [v/k/kruskal_reconstruction_tree_bottleneck.v](../../../v/k/kruskal_reconstruction_tree_bottleneck.v) |
| Zig | [zig/k/kruskal_reconstruction_tree_bottleneck.zig](../../../zig/k/kruskal_reconstruction_tree_bottleneck.zig) |
