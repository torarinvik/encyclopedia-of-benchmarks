# Naive knapsack solver

The pinned C# solver makes one greedy pass over items in input order. It admits an item when its weight fits in the remaining capacity; its value selector is not used.

## Contract

- The `i64_array_scalar` input is `[capacity, item_count, weight_0, ..., weight_n-1]`.
- Capacity and weights are integers from 0 through 1,000,000; item count is from 0 through 30. Weights are nonnegative so the bounded contract has monotone remaining capacity.
- Items are considered in input order and admitted when `current_weight + item_weight <= capacity`. This is the source heuristic, not an optimal knapsack solver.
- The result is a bitmask: bit `i` is set exactly when item `i` is admitted. Invalid shape or values return -1.

[`workload.json`](workload.json) includes source-style cases, order-sensitive greedy choices, zero weights, and malformed inputs.

## Implementations

- C: [`c/k/naive_knapsack_solver.c`](../../../c/k/naive_knapsack_solver.c)
- C3: [`c3/k/naive_knapsack_solver.c3`](../../../c3/k/naive_knapsack_solver.c3)
- C++: [`cpp/k/naive_knapsack_solver.cpp`](../../../cpp/k/naive_knapsack_solver.cpp)
- Elisa: [`elisa/k/naive_knapsack_solver.elisa`](../../../elisa/k/naive_knapsack_solver.elisa)
- Nim: [`nim/k/naive_knapsack_solver.nim`](../../../nim/k/naive_knapsack_solver.nim)
- Odin: [`odin/k/naive_knapsack_solver.odin`](../../../odin/k/naive_knapsack_solver.odin)
- Rust: [`rust/k/naive_knapsack_solver.rs`](../../../rust/k/naive_knapsack_solver.rs)
- V: [`v/k/naive_knapsack_solver.v`](../../../v/k/naive_knapsack_solver.v)
- Zig: [`zig/k/naive_knapsack_solver.zig`](../../../zig/k/naive_knapsack_solver.zig)

The implementation follows the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/NaiveKnapsackSolver.cs), whose `Solve` method scans each item once and adds it if the cumulative weight fits.
