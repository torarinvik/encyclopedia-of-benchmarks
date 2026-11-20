# Tree-path distinct colors with Mo's algorithm

This benchmark answers static distinct-color queries on simple paths in one
undirected tree. It uses a doubled Euler walk: each vertex appears once on
entry and once on exit, and moving a Mo window toggles that vertex's active
state. Queries are mapped to Euler intervals; a lowest common ancestor outside
an interval is temporarily toggled while recording its answer.

Input is `[n,q,colors[n],(edge_u,edge_v)*(n-1),(query_u,query_v)*q]`.
There are 1 through 32 vertices and 0 through 32 queries. Colors are arbitrary
signed 64-bit integers. The edges, in any order, must form a simple tree with
zero-based vertex labels. Queries may repeat and endpoints may be equal.
The output is one little-endian signed 64-bit distinct-color count per query,
in input order. Invalid or null input returns `-1`; null or short output
returns `-2` without writes. The largest valid input has 160 words, and the
largest output has 256 bytes. The workload reserves a conservative total
working-storage cap of 16384 bytes, including fixed graph, Euler, query, color,
answer, and call-stack state.

The ports use a dense bounded adjacency table, DFS entry/exit positions, parent
climbing for LCA, and alternating right-endpoint Mo ordering. Their local
preprocessing and per-query LCA work are bounded by `O(n^2 + qn)`; Mo ordering
adds `O(q log q)`, and the usual square-root ordering bounds window movement
by `O((n+q) sqrt(n))`. The implementation stores `O(n^2+q)` bounded state.
The small local limits define a compiler benchmark; they do not claim
large-instance performance.

The primary reference reconstructs each requested path by a graph search and
counts its colors directly. The independent reference climbs both endpoints
to their LCA and accumulates colors on the two path halves. The package-local
[`verify_workload.py`](verify_workload.py) statically checks metadata, fixture
answers against both references, and all ten source paths. The workload
includes ancestor and non-ancestor paths, repeated colors, singleton paths,
repeated queries, empty query lists, malformed trees and endpoints, and output
capacity errors.

The algorithm is described by [OI Wiki's tree Mo article](https://oi-wiki.org/misc/mo-algo-on-tree/).
The page is used only to identify the method; this contract, workload, and
clean-room implementations are independently authored. No source code, problem
text, examples, or fixtures are reused.

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/tree_path_distinct_mo.c`](../../../c/t/tree_path_distinct_mo.c) |
| C3 | [`c3/t/tree_path_distinct_mo.c3`](../../../c3/t/tree_path_distinct_mo.c3) |
| C++ | [`cpp/t/tree_path_distinct_mo.cpp`](../../../cpp/t/tree_path_distinct_mo.cpp) |
| Elisa | [`elisa/t/tree_path_distinct_mo.elisa`](../../../elisa/t/tree_path_distinct_mo.elisa) |
| Mojo | [`mojo/t/tree_path_distinct_mo.mojo`](../../../mojo/t/tree_path_distinct_mo.mojo) |
| Nim | [`nim/t/tree_path_distinct_mo.nim`](../../../nim/t/tree_path_distinct_mo.nim) |
| Odin | [`odin/t/tree_path_distinct_mo.odin`](../../../odin/t/tree_path_distinct_mo.odin) |
| Rust | [`rust/t/tree_path_distinct_mo.rs`](../../../rust/t/tree_path_distinct_mo.rs) |
| V | [`v/t/tree_path_distinct_mo.v`](../../../v/t/tree_path_distinct_mo.v) |
| Zig | [`zig/t/tree_path_distinct_mo.zig`](../../../zig/t/tree_path_distinct_mo.zig) |

These drafts have not been compiled or executed. No programs, tests, builds,
compilers, checkers, or benchmarks were run.
