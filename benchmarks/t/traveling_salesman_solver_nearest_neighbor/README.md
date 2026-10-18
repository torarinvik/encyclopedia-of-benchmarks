# C# traveling salesman nearest-neighbor solver

This package follows `TravelingSalesmanSolver.SolveNearestNeighbor` from the pinned C# source. Starting at the supplied city, it repeatedly visits the closest unvisited city, then closes the route back to the start. This greedy route is not guaranteed to be optimal.

## Contract

- The `i64_array_float64` input is `[selector, n, start, distance_0_0, distance_0_1, ...]`, with the matrix in row-major order. The matrix must be square, `n` is 1–8, `start` is in `[0,n)`, and entries are integers from 0 through 1,000.
- Selector `0` returns the route distance. Selectors `1` through `n+1` return route positions 0 through `n` as exactly representable binary64 integers. For one city, the source returns `[start,start]` and adds the diagonal distance.
- When several unvisited cities have the same minimum outgoing distance, the source retains the lowest city index because it scans indices in ascending order and updates only on a strict decrease. Distances are accumulated in route order.
- Invalid framing, selector, dimension, start, or edge value returns `-1e300`. Valid outputs are exact integers, so the workload uses zero comparison tolerance.

The selector projects the source tuple's route and distance into separate scalar calls. The bounded complete matrix domain always provides a next city until every city is visited.

See [workload](workload.json), the [shared oracle](../../traveling_salesman_solver_oracle.py), and the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/TravelingSalesman/TravelingSalesmanSolver.cs).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/traveling_salesman_solver_nearest_neighbor.c`](../../../c/t/traveling_salesman_solver_nearest_neighbor.c) |
| C3 | [`c3/t/traveling_salesman_solver_nearest_neighbor.c3`](../../../c3/t/traveling_salesman_solver_nearest_neighbor.c3) |
| C++ | [`cpp/t/traveling_salesman_solver_nearest_neighbor.cpp`](../../../cpp/t/traveling_salesman_solver_nearest_neighbor.cpp) |
| Elisa | [`elisa/t/traveling_salesman_solver_nearest_neighbor.elisa`](../../../elisa/t/traveling_salesman_solver_nearest_neighbor.elisa) |
| Nim | [`nim/t/traveling_salesman_solver_nearest_neighbor.nim`](../../../nim/t/traveling_salesman_solver_nearest_neighbor.nim) |
| Odin | [`odin/t/traveling_salesman_solver_nearest_neighbor.odin`](../../../odin/t/traveling_salesman_solver_nearest_neighbor.odin) |
| Rust | [`rust/t/traveling_salesman_solver_nearest_neighbor.rs`](../../../rust/t/traveling_salesman_solver_nearest_neighbor.rs) |
| V | [`v/t/traveling_salesman_solver_nearest_neighbor.v`](../../../v/t/traveling_salesman_solver_nearest_neighbor.v) |
| Zig | [`zig/t/traveling_salesman_solver_nearest_neighbor.zig`](../../../zig/t/traveling_salesman_solver_nearest_neighbor.zig) |
