# DSATUR greedy graph coloring

This profile implements Brélaz's saturation-degree greedy coloring rule. At
each round it chooses an uncolored vertex with the most distinct colors among
its already-colored neighbors, then the most uncolored neighbors, then the
lowest vertex ID. It assigns the lowest available color and updates the
remaining vertices' saturation sets and residual degrees.

The dynamic selection rule differs from the local fixed-order greedy graph
coloring, which chooses a static vertex order, and from the exact coloring
packages, which search for a minimum coloring. DSATUR returns a proper greedy
coloring but is a heuristic for the chromatic number on general graphs.

## Contract

The `i64_array_scalar` input is `[n,m,(u,v)*m]`, with `1 <= n <= 12`,
`0 <= m <= 66`, exact length `2 + 2*m`, maximum valid length 134, and maximum
parseable length 135. Every edge must be a canonical pair `0 <= u < v < n`;
loops and duplicate edges are invalid. Edge records may appear in any order.
Null, invalid, or incorrectly sized input returns `-1`.

Vertices use IDs `0..n-1`, colors start at zero, and all deterministic ties
follow the selection rule above. The result packs the color count into bits
48 and above and the 4-bit color of vertex `i` at bit offset `4*i`:

`(color_count << 48) | sum(color[i] << (4*i))`

The bounded ports use an adjacency matrix and direct per-round selection in
O(n^2 + m) time and O(n^2) space. Two references use different selection
updates, and the workload covers saturation updates, residual-degree and ID
ties, sparse and dense graphs, invalid frames, and the maximum graph.

| Language | Port |
|---|---|
| C | [c/d/dsatur_greedy_coloring.c](../../../c/d/dsatur_greedy_coloring.c) |
| C3 | [c3/d/dsatur_greedy_coloring.c3](../../../c3/d/dsatur_greedy_coloring.c3) |
| C++ | [cpp/d/dsatur_greedy_coloring.cpp](../../../cpp/d/dsatur_greedy_coloring.cpp) |
| Elisa | [elisa/d/dsatur_greedy_coloring.elisa](../../../elisa/d/dsatur_greedy_coloring.elisa) |
| Mojo | [mojo/d/dsatur_greedy_coloring.mojo](../../../mojo/d/dsatur_greedy_coloring.mojo) |
| Nim | [nim/d/dsatur_greedy_coloring.nim](../../../nim/d/dsatur_greedy_coloring.nim) |
| Odin | [odin/d/dsatur_greedy_coloring.odin](../../../odin/d/dsatur_greedy_coloring.odin) |
| Rust | [rust/d/dsatur_greedy_coloring.rs](../../../rust/d/dsatur_greedy_coloring.rs) |
| V | [v/d/dsatur_greedy_coloring.v](../../../v/d/dsatur_greedy_coloring.v) |
| Zig | [zig/d/dsatur_greedy_coloring.zig](../../../zig/d/dsatur_greedy_coloring.zig) |

The algorithm follows Brélaz's [New Methods to Color the Vertices of a
Graph](https://doi.org/10.1145/359094.359101) (1979). Only algorithmic ideas
are used; code, examples, and prose are independently authored.
