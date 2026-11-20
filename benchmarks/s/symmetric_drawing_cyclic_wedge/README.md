# Cyclic symmetric-drawing wedge extraction

This package profiles `Find_Wedge_Cyclic` from Chapter 654's Cyclic Case. It
accepts an already embedded graph and an already identified rotational
automorphism. It returns one wedge's boundary paths and its induced subgraph.
It does not find the automorphism group, construct coordinates with CYN, or
replicate and merge wedge drawings.

## Contract

The input is a signed-i64 array:

```text
[n,k,b,outer_cycle[b],(degree[x],clockwise_neighbors[x]...)*n,rotation_permutation[n]]
```

Vertices use IDs `0..n-1`, `4<=n<=8`; `3<=k<=8` is the exact rotational
automorphism order, and `k<=b<=n` is the outer-face length with `b` divisible
by `k`. Each row gives the distinct neighbors in clockwise cyclic order. Face
walking takes the next clockwise neighbor after the incoming edge, matching
the local rotation-system and Chapter 650 embedding profiles. The directed
outer cycle must match one face walk up to cyclic shift.

The graph must be simple, connected, 3-vertex-connected, and represented by a
spherical rotation system. The permutation must preserve adjacency and each
clockwise row, have exact order `k`, fix exactly one vertex (the center), put
every other vertex in a length-`k` orbit, and advance the outer face by exactly
`b/k` positions. This makes the chosen positive direction explicit.

The algorithm selects the closest outer vertex to the center; ties choose the
lowest vertex ID. For that endpoint it chooses the lexicographically smallest
shortest path under vertex-ID order. This is `P1`. `P2` is the image of `P1`
under the supplied generator. `P0` is the outer-face path from `P1`'s endpoint
to `P2`'s endpoint in the generator direction. The profile accepts only cases
where these form a simple sector cycle with `P1` and `P2` intersecting only at
the center.

Output is little-endian signed-i64 words:

```text
[len(P1),P1...,len(P2),P2...,len(P0),P0...,wedge_vertex_mask,wedge_edge_mask]
```

Paths include both endpoints. The closed wedge vertex mask includes cycle
vertices and vertices incident to faces on the wedge side of its boundary.
The edge mask represents the induced subgraph: bit `i` corresponds to the
`i`th lexicographically sorted undirected edge `(u,v)`, `u<v`, in the input
graph. Invalid input or an unsupported sector returns `-1`; null output or
insufficient output capacity returns `-2` without writing. The maximum valid
input has 54 words; a 55-word frame is accepted to classify a trailing word
as invalid. The single center and full-length vertex orbits mean `n` is one
plus a multiple of `k`;
the outer cycle length is also a multiple of `k`, and `m<=3*n-b-3` for a
simple plane graph with outer length `b`. These bounds put the largest frame
at the 8-vertex, 7-fold wheel. The two mapped shortest paths share only the
center, so each path has at most four vertices; the outer arc has at most
three. Output is bounded by 128 bytes; workspace is 16,384 bytes.

The primary reference uses BFS and floods the dual graph after cutting the
sector cycle. The independent reference enumerates simple paths and searches
face subsets for one whose dual cut is exactly the cycle. Both validate the
same rotation, symmetry, and framing contract by separate parsers.

## Source and distinction

Seokhee Hong, “Symmetric Graph Drawing,” *Encyclopedia of Algorithms*,
[Chapter 654](https://doi.org/10.1007/978-1-4939-2864-4_654), “Overview of the
Drawing Algorithm,” “The Cyclic Case,” Algorithm `Find_Wedge_Cyclic`. The
package implements that wedge-selection subprocedure only.

This differs from [`rotation_system_planarity_test`](../r/rotation_system_planarity_test/README.md),
which searches for an embedding rather than consuming one; from the Chapter
650 canonical-order and Schnyder packages, which return a vertex order or
colored parent edges; and from generic BFS, which does not map a path through
a rotational automorphism or extract the bounded sector's induced subgraph.
See [`RIGHTS.md`](RIGHTS.md) for clean-room provenance.

## Ports

| Language | Source |
|---|---|
| C | `c/s/symmetric_drawing_cyclic_wedge.c` |
| C3 | `c3/s/symmetric_drawing_cyclic_wedge.c3` |
| C++ | `cpp/s/symmetric_drawing_cyclic_wedge.cpp` |
| Elisa | `elisa/s/symmetric_drawing_cyclic_wedge.elisa` |
| Mojo | `mojo/s/symmetric_drawing_cyclic_wedge.mojo` |
| Nim | `nim/s/symmetric_drawing_cyclic_wedge.nim` |
| Odin | `odin/s/symmetric_drawing_cyclic_wedge.odin` |
| Rust | `rust/s/symmetric_drawing_cyclic_wedge.rs` |
| V | `v/s/symmetric_drawing_cyclic_wedge.v` |
| Zig | `zig/s/symmetric_drawing_cyclic_wedge.zig` |

`workload.json` pins rotational examples, invalid rotation/symmetry frames,
null and short output behavior, and the parseable input bound. Ten clean-room
language ports are included.
`check_inventory.py` checks package metadata and reference agreement without
calling native ports.
