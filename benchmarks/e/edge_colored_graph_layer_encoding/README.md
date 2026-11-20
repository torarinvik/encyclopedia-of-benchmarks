# Edge-colored graph layer encoding

This package benchmarks the layered reduction from an edge-colored graph to a
vertex-colored graph described in the *Encyclopedia of Algorithms* chapter
“Graph Isomorphism.” Each source vertex is copied into every color-bit layer;
an edge is copied into exactly the layers selected by its edge-color bits.
Adjacent copies of one source vertex are joined as a vertical path. The
resulting vertex colors preserve both the layer and the source vertex color.
This is a representation transform, not a canonical-labeling or isomorphism
solver.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `edge_colored_graph_layer_encoding`.
- Input is `[n,m,d,q,vertex_colors[n],(u,v,c)*m]`. There are `1<=n<=8`
  vertices, `0<=m<=28` undirected non-loop edges, `1<=d<=3` edge-color bit
  layers, and `1<=q<=3` source vertex-color classes. Vertex colors are in
  `[0,q)`; edge colors are in `[1,2^d)`. Each unordered endpoint pair occurs
  at most once. Edge order and endpoint order in the input are unrestricted.
- Source vertices use IDs `0..n-1`. The transformed graph has `N=n*d` vertices
  in layer-major order: copy `(layer,v)` has ID `layer*n+v` and vertex color
  `layer*q+vertex_colors[v]`. For every edge `(u,v,c)`, add `(layer*n+u,
  layer*n+v)` when bit `layer` of `c` is set. For each source vertex, add a
  path through its copies in increasing layer order. The output is
  `[N,K,colors[N],(a,b)*K]`, with normalized endpoints and lexicographically
  sorted edge pairs.
- Maximum valid/parseable input lengths are 96/97 i64 words. The output is at
  most 1,808 bytes and the workspace bound is 4,096 bytes. Invalid input
  returns `-1`; null or insufficient output returns `-2` without writes.
- This bounded contract profiles the reduction itself. It makes no claim about
  nauty, canonical labeling, or the asymptotic improvement mentioned in the
  chapter.

The primary reference builds a fixed color-mask matrix and emits layer edges
by scanning it. The independent reference expands the edge list into a set of
layered endpoint pairs, adds thread paths, sorts the result, and serializes it.
Fixtures cover all color bits, source vertex colors, one-layer behavior,
permuted edge records, malformed inputs, and output-capacity errors.

## Source and rights

The method is described in the *Encyclopedia of Algorithms*, Chapter 172,
[“Graph Isomorphism”](https://doi.org/10.1007/978-1-4939-2864-4_172), under
“Isomorphism of Edge-Colored Graphs.” The book allows each vertical thread to
be joined using paths or cliques; this profile chooses a path. The algorithm
description only was used. No source code, prose, figures, examples, or test
data were copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/edge_colored_graph_layer_encoding.c`](../../../c/e/edge_colored_graph_layer_encoding.c) |
| C3 | [`c3/e/edge_colored_graph_layer_encoding.c3`](../../../c3/e/edge_colored_graph_layer_encoding.c3) |
| C++ | [`cpp/e/edge_colored_graph_layer_encoding.cpp`](../../../cpp/e/edge_colored_graph_layer_encoding.cpp) |
| Elisa | [`elisa/e/edge_colored_graph_layer_encoding.elisa`](../../../elisa/e/edge_colored_graph_layer_encoding.elisa) |
| Mojo | [`mojo/e/edge_colored_graph_layer_encoding.mojo`](../../../mojo/e/edge_colored_graph_layer_encoding.mojo) |
| Nim | [`nim/e/edge_colored_graph_layer_encoding.nim`](../../../nim/e/edge_colored_graph_layer_encoding.nim) |
| Odin | [`odin/e/edge_colored_graph_layer_encoding.odin`](../../../odin/e/edge_colored_graph_layer_encoding.odin) |
| Rust | [`rust/e/edge_colored_graph_layer_encoding.rs`](../../../rust/e/edge_colored_graph_layer_encoding.rs) |
| V | [`v/e/edge_colored_graph_layer_encoding.v`](../../../v/e/edge_colored_graph_layer_encoding.v) |
| Zig | [`zig/e/edge_colored_graph_layer_encoding.zig`](../../../zig/e/edge_colored_graph_layer_encoding.zig) |

See [workload.json](workload.json), the primary and independent references,
the callable static [workload review](verify_workload.py), and
[check_inventory.py](check_inventory.py).
