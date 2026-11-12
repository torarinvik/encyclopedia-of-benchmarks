# Minimum diameter spanning tree

Choose exactly `N-1` input edges that connect every vertex and minimize the
weighted diameter of the resulting tree. The graph metric supplies a useful
lower bound: the center of any spanning tree has graph-metric eccentricity no
larger than half that tree's diameter. A shortest-path tree rooted at a graph
metric center attains the bound. The ports compute all-pairs shortest paths,
enumerate vertex centers and half-integral points on input edges using doubled
coordinates, then build a deterministic shortest-path tree from the best
center. A center inside an edge starts a two-source Dijkstra search; if its two
roots remain separate, the center edge joins the resulting trees.

## Contract

The [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/minimum_diameter_spanning_tree/task.md)
asks for the minimum diameter `X` and `N-1` indices of input edges that form
an optimal spanning tree. The graph may have parallel edges and loops; edge
weights are nonnegative, and the input graph is connected. The
[official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/minimum_diameter_spanning_tree/info.toml)
allow up to 2,000 vertices and edges and weights through 1,000,000,000.

This package uses a deliberately bounded benchmark profile: `1 <= N <= 8`,
`0 <= M <= 20`, and `0 <= w <= 9`. Input is the signed 64-bit array
`[N,M,(u,v,w)...]`; valid connected graphs retain parallel edges, self-loops,
and zero-weight edges. Malformed or disconnected inputs return `-1`. Output
is `[diameter, edge_id_0, ..., edge_id_(N-2)]`, with edge IDs referring to
input order and emitted in ascending order. Successful calls write `N` signed
64-bit little-endian values. A null or undersized output buffer returns `-2`
without writing. The maximum valid input has 62 values, one extra value is
accepted by the parser for malformed-length checks, and the maximum output is
64 bytes.

The bounded weight range lets the ports inspect every doubled edge coordinate
from `0` through `2w`; this includes all possible centers for integer edge
weights. Center ties prefer vertices before edges, then ascending vertex and
edge IDs, then ascending doubled coordinates. This deterministic witness is
only for reproducible bytes; any optimal tree is valid under the official
contract.

## Distinctness and verification

The local MST packages minimize the sum of selected edge weights. The local
[`tree_diameter`](../../t/tree_diameter/README.md) measures a supplied tree.
Neither chooses a spanning tree to minimize its diameter, so this is a distinct
graph optimization algorithm.

[`workload.json`](workload.json) includes a singleton, a triangle with a
center-vertex optimum, an edge-center path, zero-weight and parallel edges, a
self-loop, malformed disconnected input, and output-buffer errors. The
independent [`benchmarks/minimum_diameter_spanning_tree_oracle.py`](../../minimum_diameter_spanning_tree_oracle.py)
computes the deterministic center witness. Its certificate checker separately
enumerates all bounded `N-1` edge subsets, rejects non-trees, and compares the
reported diameter with the global optimum.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/minimum_diameter_spanning_tree.c`](../../../c/m/minimum_diameter_spanning_tree.c) |
| C3 | [`c3/m/minimum_diameter_spanning_tree.c3`](../../../c3/m/minimum_diameter_spanning_tree.c3) |
| C++ | [`cpp/m/minimum_diameter_spanning_tree.cpp`](../../../cpp/m/minimum_diameter_spanning_tree.cpp) |
| Elisa | [`elisa/m/minimum_diameter_spanning_tree.elisa`](../../../elisa/m/minimum_diameter_spanning_tree.elisa) |
| Mojo | [`mojo/m/minimum_diameter_spanning_tree.mojo`](../../../mojo/m/minimum_diameter_spanning_tree.mojo) |
| Nim | [`nim/m/minimum_diameter_spanning_tree.nim`](../../../nim/m/minimum_diameter_spanning_tree.nim) |
| Odin | [`odin/m/minimum_diameter_spanning_tree.odin`](../../../odin/m/minimum_diameter_spanning_tree.odin) |
| Rust | [`rust/m/minimum_diameter_spanning_tree.rs`](../../../rust/m/minimum_diameter_spanning_tree.rs) |
| V | [`v/m/minimum_diameter_spanning_tree.v`](../../../v/m/minimum_diameter_spanning_tree.v) |
| Zig | [`zig/m/minimum_diameter_spanning_tree.zig`](../../../zig/m/minimum_diameter_spanning_tree.zig) |
