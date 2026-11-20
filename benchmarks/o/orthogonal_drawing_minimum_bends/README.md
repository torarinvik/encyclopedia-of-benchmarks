# Minimum-bend orthogonal drawing flow

This package computes the minimum number of bends for a supplied simple
2-connected plane graph of maximum degree four. It returns the optimum bend
count from the chapter's integral-flow reduction; it does not construct vertex
coordinates or route the edges on a grid.

Input is
`[n,m,f,outer,(u,v)*m,(face_length,face_vertices...)*f]`. Vertices are
numbered `0..n-1`; undirected edges `(u,v)` have `u<v` and appear in
lexicographic order. Each face is a simple cyclic list of its boundary
vertices. The two sides of every edge occur once each, with opposite
directions. The graph is connected and remains connected after deleting any
one vertex, each vertex has degree 2..4, and `n-m+f=2`. The selected `outer`
face index identifies the unbounded face. Bounds are `3<=n<=8`, `n<=m<=16`,
and `2<=f<=10`; the largest valid frame is 78 signed-i64 words and 79 words
are parseable to classify a trailing word as invalid.

The supplied face walks must also form a valid local neighborhood at every
vertex. Build its link graph with one node for each incident neighbor and one
link edge for each face corner, joining that corner's predecessor and successor
neighbors. The link must be connected and every node must have degree two; at
a degree-two graph vertex the two parallel link edges are retained. This
rejects pinched face systems whose edge darts and Euler count look valid but
whose local surface around a vertex is disconnected. Both references and all
ten ports enforce this condition; package preflight pins a malformed map
whose two links at each shared vertex are disconnected.

For each graph vertex the flow network has supply 4. Each face is a sink with
demand `2*deg(f)-4` when internal and `2*deg(f)+4` when it is the selected
outer face; `deg(f)` counts boundary vertices. Every primal edge contributes
both directed arcs between its incident dual faces, each with unit cost and
lower bound zero. Every vertex-face corner contributes a zero-cost arc with
lower bound one. The ports convert these lower bounds into adjusted supplies
and demands, then solve the resulting minimum-cost integral flow. The output
is one little-endian signed-i64 word containing its cost. The chapter's
theorem equates this optimum to the minimum bend count. Maximum output is 8
bytes and fixed workspace is 8192 bytes. Invalid frames return `-1`; null
output or capacity below 8 bytes returns `-2` without writing.

The primary reference uses successive shortest augmenting paths with reduced
cost potentials and a bounded array-based Dijkstra search. The independent
reference uses Bellman-Ford over the residual network on every augmentation.
Both are clean-room references of the flow model, not translations of a
reference implementation. With at most `n+f+2<=20` flow nodes, at most 168
residual arcs, and at most 64 units of adjusted supply, the bounded running
time is `O(U*(V^2+E))`, where `U<=64`, `V<=20`, and `E<=168`.

## Source and distinction

Maurizio Patrignani, “Bend Minimization for Orthogonal Drawings of Plane
Graphs,” *Encyclopedia of Algorithms*,
[Chapter 651](https://doi.org/10.1007/978-1-4939-2864-4_651), Key Results;
Tamassia's minimum-cost flow reduction. Algorithm description only; the ports,
references, workload, and documentation are clean-room. Generic
`min_cost_max_flow` accepts an arbitrary single-source/sink network and does
not construct the plane embedding's dual/corner network or return the bend
optimum.

See [`RIGHTS.md`](RIGHTS.md) for provenance and reuse notes.

## Ports

| Language | Source |
|---|---|
| C | `c/o/orthogonal_drawing_minimum_bends.c` |
| C3 | `c3/o/orthogonal_drawing_minimum_bends.c3` |
| C++ | `cpp/o/orthogonal_drawing_minimum_bends.cpp` |
| Elisa | `elisa/o/orthogonal_drawing_minimum_bends.elisa` |
| Mojo | `mojo/o/orthogonal_drawing_minimum_bends.mojo` |
| Nim | `nim/o/orthogonal_drawing_minimum_bends.nim` |
| Odin | `odin/o/orthogonal_drawing_minimum_bends.odin` |
| Rust | `rust/o/orthogonal_drawing_minimum_bends.rs` |
| V | `v/o/orthogonal_drawing_minimum_bends.v` |
| Zig | `zig/o/orthogonal_drawing_minimum_bends.zig` |

`workload.json` pins small, maximum-size, invalid, null, and short-output
fixtures. `check_inventory.py` statically checks metadata, fixture/reference
parity, and all ten source paths; it is not run as part of writing this
package.
