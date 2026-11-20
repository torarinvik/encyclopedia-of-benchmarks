# General directed planar s-t flow (bounded Borradaile–Klein profile)

This package extends the local [`st_planar_leftmost_augmenting_flow`](../../s/st_planar_leftmost_augmenting_flow/README.md) special case. That profile assumes that `s` and `t` share an outer face and uses a supplied-order residual search directly. This package includes the general planar preprocessing: it selects a `t`-incident face as infinity, computes reverse-dual shortest-path potentials, splits the original capacities over the two dart directions, and then repeatedly saturates a leftmost residual `s`-to-`t` path. The two references differ: the primary uses the dual-potential and right-first-search procedure; the independent reference enumerates original directed cuts.

## Input and output

Input is a signed-i64 frame:

```text
[n,m,s,t,(tail,head,capacity)*m,(degree,edge_id...)*n]
```

All IDs are zero-based. Each edge tuple gives one directed arc; its underlying undirected edge may occur only once. The underlying graph must be connected and simple, and each capacity is an integer in `1..5`. For each vertex, the rotation row lists all incident edge IDs exactly once in counterclockwise cyclic order. The supplied rotation system must describe a sphere embedding; the package validates this by enumerating dart-face orbits and checking `F=m-n+2`. It does not infer an embedding from coordinates.

The bounds are `2<=n<=6`, `1<=m<=10`, at most 60 words in a valid frame and 61 words parseable. Rotations are counterclockwise rows with the supplied first entry as their explicit cyclic anchor. The chosen infinite face is the right face of the local dart that starts at `t` along its first listed incident edge, regardless of the input arc's direction. This is a deterministic refinement of the paper's choice of any face incident to `t`. Face IDs are assigned by scanning darts in increasing ID and starting a new orbit at the first unseen dart. Within each rotation row, the right-first search scans the counterclockwise-next incidence after its incoming incidence. At `t`, it starts at the first listed incidence and then scans counterclockwise. These rules make the leftmost path trace deterministic. Ripphausen-Lipa, Wagner, and Weihe define right-first DFS as taking the counterclockwise-next incidence after the leading arc in §1; Borradaile–Klein cite that procedure for their search tree.

The potential convention is explicit. For each primal dart `d`, the corresponding reverse-dual edge runs from `R(d)` to `L(d)` with length `c_in[d]`; original forward darts have their input capacity and reverse darts have length zero. Dijkstra runs from the chosen infinite face to all faces. For each input arc `a`, let `η[a]=φ[L(a)]−φ[R(a)]`. The distance inequalities give `0<=η[a]<=capacity(a)`. The transformed directional capacities are `capacity(a)-η[a]` on `a` and `η[a]` on `rev(a)`. Their sum preserves the original capacity, and the potential circulation preserves every s-t cut value.

The output is the maximum-flow value as one little-endian signed i64 word (8 bytes). Malformed input returns `-1`; null output or capacity below 8 returns `-2` without writing. Workspace is bounded to 8,192 bytes. Direct bounded Dijkstra and recomputed right-first DFS trees replace the paper's faster planar and dynamic-tree structures; this profile makes no claim to the published `O(n log n)` time bound.

## Fixtures

The workload includes a single directed bridge, a zero-flow orientation, a directed triangle with two routes, a triangular-bipyramid embedding whose source and sink poles are not cofacial, a maximum-size six-vertex/ten-edge wheel, and an asymmetric six-vertex chorded cycle. The chorded-cycle fixture has routes `s-a-x-t`, `s-a-y-t`, and `s-b-x-t`. Its selected infinite face and first `t` incidence make the first leftmost augmentation use `s-a-x-t`; a later augmentation uses the residual reverse of `a-x` to reroute through `s-b-x-a-y-t` and reaches maximum value two. Its CCW rotation rows are `[0,1] [3,0,2] [4,1] [5,2,4] [3,6] [5,6]`, making the forward/reverse scan difference explicit. Invalid fixtures cover a nonplanar rotation system, zero capacity, incomplete rotations, truncated frames, and a trailing word. Null input/output and short output capacity are also pinned.

## Sources and distinction

The operational method is Borradaile and Klein, [“An O(n log n) Algorithm for Maximum st-Flow in a Directed Planar Graph,” §3](https://doi.org/10.1145/1502793.1502798). The counterclockwise-next definition of right-first search is given in Ripphausen-Lipa, Wagner, and Weihe, [“The Vertex-Disjoint Menger Problem in Planar Graphs,” §1](https://doi.org/10.1137/S0097539793253565), which Borradaile–Klein cite for this search primitive. Chapter 626, [“Planar Maximum s-t Flow”](https://doi.org/10.1007/978-1-4939-2864-4_626), is the Encyclopedia crosswalk entry. The local st-planar package does not perform the general dual potential transformation and rejects the need for non-cofacial `s,t` cases; this profile measures those additional steps. The ports implement algorithm descriptions only. No paper code or prose is copied.

| Language | Port |
|---|---|
| C | [c/p/planar_directed_general_st_flow_borradaile_klein.c](../../../c/p/planar_directed_general_st_flow_borradaile_klein.c) |
| C3 | [c3/p/planar_directed_general_st_flow_borradaile_klein.c3](../../../c3/p/planar_directed_general_st_flow_borradaile_klein.c3) |
| C++ | [cpp/p/planar_directed_general_st_flow_borradaile_klein.cpp](../../../cpp/p/planar_directed_general_st_flow_borradaile_klein.cpp) |
| Elisa | [elisa/p/planar_directed_general_st_flow_borradaile_klein.elisa](../../../elisa/p/planar_directed_general_st_flow_borradaile_klein.elisa) |
| Mojo | [mojo/p/planar_directed_general_st_flow_borradaile_klein.mojo](../../../mojo/p/planar_directed_general_st_flow_borradaile_klein.mojo) |
| Nim | [nim/p/planar_directed_general_st_flow_borradaile_klein.nim](../../../nim/p/planar_directed_general_st_flow_borradaile_klein.nim) |
| Odin | [odin/p/planar_directed_general_st_flow_borradaile_klein.odin](../../../odin/p/planar_directed_general_st_flow_borradaile_klein.odin) |
| Rust | [rust/p/planar_directed_general_st_flow_borradaile_klein.rs](../../../rust/p/planar_directed_general_st_flow_borradaile_klein.rs) |
| V | [v/p/planar_directed_general_st_flow_borradaile_klein.v](../../../v/p/planar_directed_general_st_flow_borradaile_klein.v) |
| Zig | [zig/p/planar_directed_general_st_flow_borradaile_klein.zig](../../../zig/p/planar_directed_general_st_flow_borradaile_klein.zig) |

The package references, workload, rights note, and static inventory are listed in `inventory.json`. The package is registered in the shared `i64_array_bytes_output` runner, verifier, and catalog. References, fixtures, and programs have not been executed.
