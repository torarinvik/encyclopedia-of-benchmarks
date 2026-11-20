# Grid shortest path with obstacle elimination

This package computes a shortest four-neighbor path through a binary grid when
entering an obstacle consumes one unit of a supplied elimination budget. It is
distinct from local [Lee BFS](../../l/lee_breadth_first_search/README.md) and
[bidirectional A*](../../b/bidirectional_a_star/README.md), which track grid
position without a resource budget, and from
[unique paths with obstacles](../../u/unique_paths_with_obstacles/README.md),
which counts only monotone right/down routes.

## Bounded contract

The i64-array scalar input is [rows, columns, budget, cells...], with cells in
row-major order. Dimensions are 1 through 6, budget is 0 through 6, every cell
is 0 (free) or 1 (obstacle), and the frame length is exactly
3 + rows*columns. The upper-left and lower-right cells must be free. The
maximum valid frame is 39 words; a 40-word frame is parseable but invalid.
The function returns the minimum number of moves, or -1 when no route exists.
Malformed or null input returns -2.

The primary implementation runs BFS over product states (cell, remaining
eliminations). A state is visited at most once. The independent reference uses
repeated edge relaxation over the same bounded product graph, not a queue
traversal. The maximum state count is 6*6*7 = 252. The BFS takes O(S+E) time
and O(S) space, where S=rows*columns*(budget+1) and E<=4S. The independent
relaxation scans all S states per pass for at most S passes, taking
O(S*(S+E)) time and O(S+E) space. Native ports use fixed arrays;
the conservative internal workspace cap is 8,192 bytes.

## Provenance and rights

The public title [LeetCode 1293, Shortest Path in a Grid with Obstacles
Elimination](https://leetcode.com/problems/shortest-path-in-a-grid-with-obstacles-elimination/)
supplied the discovery lead only. The product-state interpretation is
independently specified as a finite unweighted graph and uses the standard BFS
shortest-path property described by [CP-Algorithms](https://cp-algorithms.com/graph/breadth-first-search.html). No
problem statement, examples, editorial text, tests, submissions, or code were
copied. The workload fixtures and all implementations are original. See
RIGHTS.md for the clean-room record.

## Workload and inventory

workload.json contains hand-pinned small grids, an exact maximum-frame open
grid, resource-sensitive reachability, malformed frames, and null input.
verify_workload.py compares the FIFO BFS with an independent Bellman-Ford-style
relaxation reference. check_inventory.py checks the ten source paths and
metadata without compiling or running a port.

| Language | Source |
|---|---|
| C | c/g/grid_shortest_path_obstacle_elimination.c |
| C3 | c3/g/grid_shortest_path_obstacle_elimination.c3 |
| C++ | cpp/g/grid_shortest_path_obstacle_elimination.cpp |
| Elisa | elisa/g/grid_shortest_path_obstacle_elimination.elisa |
| Mojo | mojo/g/grid_shortest_path_obstacle_elimination.mojo |
| Nim | nim/g/grid_shortest_path_obstacle_elimination.nim |
| Odin | odin/g/grid_shortest_path_obstacle_elimination.odin |
| Rust | rust/g/grid_shortest_path_obstacle_elimination.rs |
| V | v/g/grid_shortest_path_obstacle_elimination.v |
| Zig | zig/g/grid_shortest_path_obstacle_elimination.zig |
