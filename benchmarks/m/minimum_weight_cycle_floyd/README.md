# Minimum-weight cycle by incremental Floyd–Warshall

This benchmark returns the minimum total edge weight of a simple undirected
cycle containing at least three vertices. A valid acyclic graph returns an
8-byte little-endian signed-i64 payload containing `-1`.

The input is `[n,m,(u,v,w)*m]`. Vertex IDs are zero-based, `3 <= n <= 9`,
`0 <= m <= n*(n-1)/2`, and each undirected endpoint pair may occur once in
either orientation and any record order. Self-loops, duplicate undirected
pairs, and weights outside `1..=1000` are invalid. The exact frame is
`2+3*m` i64 words; maximum valid and parseable lengths are 110 and 111.
Malformed or null input returns `-1` without writes. A valid input with null
output or fewer than 8 output bytes returns `-2` without writes. A successful
call returns 8, even when the payload is `-1` for an acyclic graph.

For each vertex `k` in increasing order, the primary algorithm first checks
every pair `i<j<k`: an original edge from `i` to `k`, an original edge from
`k` to `j`, and the current shortest path from `i` to `j` form a candidate
cycle whose other vertices are below `k`. It then relaxes all pairs through
`k`. The primary takes `O(n^3+m)` time and `O(n^2)` space. The independent
reference enumerates simple cycles, fixing the least vertex as start and
considering one of the two directions; its time is proportional to the
number of simple cycles and its space is `O(n^2)`. Both operate within the
4096-byte declared workspace cap.

This is not directed girth: [`directed_girth_bfs`](../directed_girth_bfs/README.md)
finds an unweighted shortest directed cycle using repeated BFS. It also differs
from [`minimum_cycle_basis_horton`](../minimum_cycle_basis_horton/README.md),
which minimizes the sum of a full GF(2) cycle basis. Here the target is one
minimum-weight undirected cycle, found with the Floyd cycle invariant.

The algorithm is described in [OI Wiki — Minimum Cycle](https://oi-wiki.org/graph/min-cycle/).
The page is provenance only; the profile, workload, references, and ports are
clean-room work. See [RIGHTS.md](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/minimum_weight_cycle_floyd.c`](../../../c/m/minimum_weight_cycle_floyd.c) |
| C3 | [`c3/m/minimum_weight_cycle_floyd.c3`](../../../c3/m/minimum_weight_cycle_floyd.c3) |
| C++ | [`cpp/m/minimum_weight_cycle_floyd.cpp`](../../../cpp/m/minimum_weight_cycle_floyd.cpp) |
| Elisa | [`elisa/m/minimum_weight_cycle_floyd.elisa`](../../../elisa/m/minimum_weight_cycle_floyd.elisa) |
| Mojo | [`mojo/m/minimum_weight_cycle_floyd.mojo`](../../../mojo/m/minimum_weight_cycle_floyd.mojo) |
| Nim | [`nim/m/minimum_weight_cycle_floyd.nim`](../../../nim/m/minimum_weight_cycle_floyd.nim) |
| Odin | [`odin/m/minimum_weight_cycle_floyd.odin`](../../../odin/m/minimum_weight_cycle_floyd.odin) |
| Rust | [`rust/m/minimum_weight_cycle_floyd.rs`](../../../rust/m/minimum_weight_cycle_floyd.rs) |
| V | [`v/m/minimum_weight_cycle_floyd.v`](../../../v/m/minimum_weight_cycle_floyd.v) |
| Zig | [`zig/m/minimum_weight_cycle_floyd.zig`](../../../zig/m/minimum_weight_cycle_floyd.zig) |

`primary_oracle.py`, `independent_oracle.py`, `workload.json`,
`verify_workload.py`, and the static inventory checker accompany these ports.
No executable checks have been run.
