# D* Lite incremental replanning

This profile maintains shortest-path estimates to a fixed goal while the
planning start moves and directed edge costs change. D* Lite stores `g` and
`rhs` values, queues inconsistent vertices, and repairs the affected portion
of the search after each event. It uses Manhattan distance as a consistent
heuristic on the directed grid because every arc joins adjacent cells and has
positive cost. Existing A* and Dijkstra profiles perform static searches or
recompute paths; they do not maintain D* Lite's incremental consistency state.

## Contract

The exported scalar symbol is `d_star_lite_incremental_replanning`. Input is
`[H,W,E,Q,start,goal,(u,v,c)*E,(new_start,edge_id,new_cost)*Q]`. Grid
dimensions are each in `[1,4]` and the grid has 2 through 16 vertices, numbered
row-major. The graph is directed and simple; every arc joins orthogonally
adjacent cells and has a cost in `[1,9]`. Each of up to 16 events moves the
start to any valid vertex and replaces one existing arc's cost with a value in
`[1,9]`. Repeated and no-op updates are permitted. Exact input length is
`6+3E+3Q`; maximum valid and parseable lengths are 198 and 199 signed 64-bit
values. Invalid input returns `-1`.

For each event, update `km` by the Manhattan distance from the previous start
to the new start, apply the directed cost change, call `UpdateVertex` on that
arc's tail, and run `ComputeShortestPath`. The open set contains one entry per
inconsistent vertex and is implemented as a bounded array with deterministic
minimum selection by `(key1,key2,vertex_id)`. The key is
`(min(g,rhs)+h(start,u)+km,min(g,rhs))`; `rhs(u)` is the minimum outgoing
`cost(u,v)+g(v)`, while `rhs(goal)=0`.

After each event, encode the distance as its exact value up to 135, or 136 when
the goal is unreachable. Encode the next vertex as `vertex_id+1`, choosing
the smallest ID among shortest-path successors; use zero when the start is the
goal or unreachable. The checksum is
`sum(t*(distance_code+1)*(next_code+1))` for one-based event index `t`. Its
conservative maximum is 316,744. With `R` total queue removals, the array-backed
primary uses `O(E+RV+QE)` time and `O(V+E+Q)` space; the independent oracle
recomputes all-pairs distances after each event in `O(QV^3)` time.

## Provenance and rights

D* Lite follows Sven Koenig and Maxim Likhachev, [“D* Lite,” AAAI 2002](https://cdn.aaai.org/AAAI/2002/AAAI02-072.pdf),
with bibliographic details at the [CMU publication record](https://publications.ri.cmu.edu/d-lite).
The paper is cited for the algorithm idea only. The bounded contract, fixtures,
oracles, and language ports are independently written; no paper text or code is
reused. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[D* Lite repair oracle](../../d_star_lite_incremental_replanning_oracle.py),
the [Floyd–Warshall verifier](../../d_star_lite_incremental_replanning_verifier_oracle.py),
and [static package inventory](../../check_d_star_lite_incremental_replanning_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/d_star_lite_incremental_replanning.c`](../../../c/d/d_star_lite_incremental_replanning.c) |
| C3 | [`c3/d/d_star_lite_incremental_replanning.c3`](../../../c3/d/d_star_lite_incremental_replanning.c3) |
| C++ | [`cpp/d/d_star_lite_incremental_replanning.cpp`](../../../cpp/d/d_star_lite_incremental_replanning.cpp) |
| Elisa | [`elisa/d/d_star_lite_incremental_replanning.elisa`](../../../elisa/d/d_star_lite_incremental_replanning.elisa) |
| Mojo | [`mojo/d/d_star_lite_incremental_replanning.mojo`](../../../mojo/d/d_star_lite_incremental_replanning.mojo) |
| Nim | [`nim/d/d_star_lite_incremental_replanning.nim`](../../../nim/d/d_star_lite_incremental_replanning.nim) |
| Odin | [`odin/d/d_star_lite_incremental_replanning.odin`](../../../odin/d/d_star_lite_incremental_replanning.odin) |
| Rust | [`rust/d/d_star_lite_incremental_replanning.rs`](../../../rust/d/d_star_lite_incremental_replanning.rs) |
| V | [`v/d/d_star_lite_incremental_replanning.v`](../../../v/d_star_lite_incremental_replanning.v) |
| Zig | [`zig/d/d_star_lite_incremental_replanning.zig`](../../../zig/d_star_lite_incremental_replanning.zig) |
