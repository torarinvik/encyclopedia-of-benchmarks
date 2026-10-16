# Branch-and-bound 0/1 knapsack

This benchmark ports the pinned TheAlgorithms/C-Sharp breadth-first branch-and-bound solver. It uses positive integer weights and values, sorts items by descending value density, explores include/exclude nodes in breadth-first order, and uses the fractional relaxation to prune subtrees. The source's ascending density sort makes its stated upper bound underestimate feasible completions; the benchmark corrects that ordering so the solver returns an optimal selection.

## Input and output

Input is `[item_count, capacity, weight_0, value_0, ...]`. It allows 0..8 items, positive weights and values through 1,000, and capacity 0..8,000. Density ties retain input order. The return value is the selected item count; output contains each selected input index as one byte, in reverse density-sorted path order, matching the source's backtracking output order.

Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing. The maximum search tree has 511 nodes. The contract is deterministic and uses only portable integer operations plus the standard floating-point fractional bound.

## Workload

The workload covers empty and zero-capacity inputs, exact fits, infeasible items, density ties, fractional upper bounds, optimal subset selection, and the source ordering defect.

## Verification

Run the independent exhaustive-subset and fractional-bound verifier for all nine ports:

```sh
python3 benchmarks/verify_branch_and_bound_knapsack_solver.py
```

## Upstream reference

- [TheAlgorithms/C-Sharp `BranchAndBoundKnapsackSolver.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/BranchAndBoundKnapsackSolver.cs)
- [TheAlgorithms/C-Sharp `BranchAndBoundNode.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/BranchAndBoundNode.cs)
