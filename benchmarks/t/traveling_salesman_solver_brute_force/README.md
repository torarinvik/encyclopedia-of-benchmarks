# C# traveling salesman brute-force solver

This package follows `TravelingSalesmanSolver.SolveBruteForce` from the pinned C# source. It fixes city 0 as the start and enumerates permutations of cities 1 through `n-1`, returning the first minimum-cost closed route in permutation order.

## Contract

- The `i64_array_float64` input is `[selector, n, distance_0_0, distance_0_1, ...]`, with the matrix in row-major order. The matrix must be square, `n` is 2–8, and its entries are integers from 0 through 1,000. The diagonal is accepted but never read by this method.
- Selector `0` returns the route distance. Selectors `1` through `n+1` return route positions 0 through `n` as exactly representable binary64 integers. The route is `[0, permutation(1..n-1), 0]`.
- For tied minimum routes, preserve the source permutation order: lexicographically ascending city order, with the first route retained. Distances are accumulated from the route's directed edges in order.
- Invalid framing, selector, dimension, or edge value returns `-1e300`. Valid outputs are exact integers, so the workload uses zero comparison tolerance.

The selector projects the source tuple's route and distance into separate scalar calls while retaining the complete source result. The pinned method returns an empty route and `double.MaxValue` only if no candidate beats that sentinel; the bounded finite integer domain always has at least one route.

See [workload](workload.json), the [shared oracle](../../traveling_salesman_solver_oracle.py), and the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/TravelingSalesman/TravelingSalesmanSolver.cs).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/traveling_salesman_solver_brute_force.c`](../../../c/t/traveling_salesman_solver_brute_force.c) |
| C3 | [`c3/t/traveling_salesman_solver_brute_force.c3`](../../../c3/t/traveling_salesman_solver_brute_force.c3) |
| C++ | [`cpp/t/traveling_salesman_solver_brute_force.cpp`](../../../cpp/t/traveling_salesman_solver_brute_force.cpp) |
| Elisa | [`elisa/t/traveling_salesman_solver_brute_force.elisa`](../../../elisa/t/traveling_salesman_solver_brute_force.elisa) |
| Nim | [`nim/t/traveling_salesman_solver_brute_force.nim`](../../../nim/t/traveling_salesman_solver_brute_force.nim) |
| Odin | [`odin/t/traveling_salesman_solver_brute_force.odin`](../../../odin/t/traveling_salesman_solver_brute_force.odin) |
| Rust | [`rust/t/traveling_salesman_solver_brute_force.rs`](../../../rust/t/traveling_salesman_solver_brute_force.rs) |
| V | [`v/t/traveling_salesman_solver_brute_force.v`](../../../v/t/traveling_salesman_solver_brute_force.v) |
| Zig | [`zig/t/traveling_salesman_solver_brute_force.zig`](../../../zig/t/traveling_salesman_solver_brute_force.zig) |
