# Same-value teleport BFS

Find the fewest unweighted moves from the first position of an integer array
to its last position. A move goes to an adjacent index or to a different index
with the same value. The primary algorithm groups indices by value, runs BFS,
and consumes each value group on its first expansion so its complete group is
scanned only once.

## Contract

The `i64_array_scalar` input is `[n, values...]`, with `1 <= n <= 64`, exactly
`n` values, and each value in `[-64,64]`. Return the minimum number of moves;
a singleton array returns zero. Malformed input returns `-2`. Adjacent moves
make every valid instance reachable.

The bounded value domain supports direct bucket indexing. The primary method
takes `O(n)` time and `O(n)` workspace (capped at 3,072 bytes). The independent reference constructs
neighbors by direct pairwise comparison and runs ordinary BFS in `O(n^2)` time.

## Source and distinction

The [LeetCode 1345 title](https://leetcode.com/problems/jump-game-iv/) was used
for discovery and to identify the equal-value transition. The general shortest
path method is ordinary BFS on an unweighted graph, as described by
[CP-Algorithms](https://cp-algorithms.com/graph/breadth-first-search.html).
The graph is implicit: each value class forms a clique, but the primary avoids
materializing those edges by expanding each class once. This differs from
[`jump_game`](../jump_game/README.md), which scans reachability bounds,
[`jump_game_ii`](../jump_game_ii/README.md), which follows array-provided jump
lengths, and [`min_number_of_jumps`](../../m/min_number_of_jumps/README.md),
which solves a separate forward-jump contract.

Only the task's transition idea and the BFS method were consulted. No source
code, statement text, examples, tests, or submissions were reused. See
[`RIGHTS.md`](RIGHTS.md).

## Workload and ports

[`workload.json`](workload.json) covers equal-value teleports, adjacent-only
routes, multiple value classes, singleton input, maximum input, and malformed
frames. The package has ten native ports and two structurally different
references. No programs, tests, scripts, checkers, builds, compilers,
profilers, or benchmarks were run.

| Language | Source |
| --- | --- |
| C | [`c/s/same_value_teleport_bfs.c`](../../../c/s/same_value_teleport_bfs.c) |
| C3 | [`c3/s/same_value_teleport_bfs.c3`](../../../c3/s/same_value_teleport_bfs.c3) |
| C++ | [`cpp/s/same_value_teleport_bfs.cpp`](../../../cpp/s/same_value_teleport_bfs.cpp) |
| Elisa | [`elisa/s/same_value_teleport_bfs.elisa`](../../../elisa/s/same_value_teleport_bfs.elisa) |
| Mojo | [`mojo/s/same_value_teleport_bfs.mojo`](../../../mojo/s/same_value_teleport_bfs.mojo) |
| Nim | [`nim/s/same_value_teleport_bfs.nim`](../../../nim/s/same_value_teleport_bfs.nim) |
| Odin | [`odin/s/same_value_teleport_bfs.odin`](../../../odin/s/same_value_teleport_bfs.odin) |
| Rust | [`rust/s/same_value_teleport_bfs.rs`](../../../rust/s/same_value_teleport_bfs.rs) |
| V | [`v/s/same_value_teleport_bfs.v`](../../../v/s/same_value_teleport_bfs.v) |
| Zig | [`zig/s/same_value_teleport_bfs.zig`](../../../zig/s/same_value_teleport_bfs.zig) |
