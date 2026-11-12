# Games on arbitrary directed graphs

This benchmark classifies each vertex of a finite directed graph for the normal-play game in which players alternate by following an outgoing edge. A vertex with no outgoing edge is losing for the player whose turn begins there. The returned status is `1` for a forced win, `2` for a forced loss, and `0` for a draw. Status bytes follow ascending vertex ID; the first byte is the vertex count.

The implementation uses reverse-edge retrograde propagation. It starts from terminal losses, marks each predecessor of a loss as winning, and marks a predecessor losing once every distinct successor is winning. Vertices left unresolved are draws. Repeated arcs are coalesced and self-loops are allowed. The bounded profile is `0 <= V <= 16`, `0 <= E <= 32`, with input `[V,E,(u,v)*E]` and a maximum of 66 input integers. The output is at most 17 bytes. It uses `O(V+E)` time and bounded `O(V+E)` storage.

This is a cyclic-graph position classifier. It differs from [`sprague_grundy_theorem`](../../s/sprague_grundy_theorem/README.md), which computes mex values for a subtraction-game heap, as well as board-search minimax benchmarks.

The output-buffer capacity is bounded at 17 bytes; internal state uses fixed arrays sized for the 16-vertex, 32-edge profile.

The algorithm is independently implemented from the high-level description in [CP-Algorithms: Games on arbitrary graphs](https://cp-algorithms.com/game_theory/games_on_graphs.html), licensed CC BY-SA 4.0. No source code or test data is copied. The primary oracle uses reverse-edge propagation; the independent oracle repeatedly applies the attractor rules synchronously until reaching a fixed point.

## Language ports

- [C](../../../c/g/games_on_arbitrary_graphs.c)
- [C3](../../../c3/g/games_on_arbitrary_graphs.c3)
- [C++](../../../cpp/g/games_on_arbitrary_graphs.cpp)
- [Elisa](../../../elisa/g/games_on_arbitrary_graphs.elisa)
- [Mojo](../../../mojo/g/games_on_arbitrary_graphs.mojo)
- [Nim](../../../nim/g/games_on_arbitrary_graphs.nim)
- [Odin](../../../odin/g/games_on_arbitrary_graphs.odin)
- [Rust](../../../rust/g/games_on_arbitrary_graphs.rs)
- [V](../../../v/g/games_on_arbitrary_graphs.v)
- [Zig](../../../zig/g/games_on_arbitrary_graphs.zig)

The package-local workload and static inventory checker are [`workload.json`](workload.json) and [`verify_games_on_arbitrary_graphs_package.py`](verify_games_on_arbitrary_graphs_package.py).
