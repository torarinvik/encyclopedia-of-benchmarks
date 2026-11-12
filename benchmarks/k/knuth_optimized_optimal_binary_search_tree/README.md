# Knuth-optimized optimal binary search tree

This profile minimizes successful-search cost for ordered key frequencies.
For an interval `[i,j]`, the root candidate `r` has cost
`sum(f[i..j]) + cost[i..r-1] + cost[r+1..j]`, with empty intervals costing
zero. It differs computationally from the existing cubic scan: Knuth's
monotone-root bounds restrict the next interval's search to
`opt[i][j-1]..opt[i+1][j]`, reducing the root-search work to O(n^2).

Local bounds are `1 <= n <= 64` and `0 <= frequency <= 1,000,000`. Equal-cost
roots choose the leftmost index (the first strict minimum). The frequency
sequence is already in ascending key order, as in the existing package.
Maximum possible cost is at most `n^2 * max_frequency`, which fits signed
64-bit output. This benchmark compares the optimized computation to the
existing cubic implementation; it is not a distinct objective or recurrence.

## ABI

Symbol: `knuth_optimized_optimal_binary_search_tree`, ABI
`i64_array_scalar`. Input is `[n, frequency_0, ..., frequency_(n-1)]`.
Malformed input returns `-1`; success returns the minimum weighted search
cost. Primary oracle uses Knuth root bounds; independent verifier enumerates
every possible root. See [workload.json](workload.json) and the two oracle
files linked below.

## Provenance and rights

The recurrence and ordered-frequency contract are documented by the existing
[optimal-BST package](../optimal_binary_search_tree/README.md). The local
catalog records a Java implementation using Knuth root bounds; see the
[pinned Java reference](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/OptimalBinarySearchTree.java)
and the pinned
[Python recurrence reference](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/optimal_binary_search_tree.py).
This package is independently written; no upstream source text or code is
copied. See [RIGHTS.md](RIGHTS.md).

Primary oracle: [`knuth_optimized_optimal_binary_search_tree_oracle.py`](../../knuth_optimized_optimal_binary_search_tree_oracle.py).
Independent verifier: [`knuth_optimized_optimal_binary_search_tree_verifier_oracle.py`](../../knuth_optimized_optimal_binary_search_tree_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/k/knuth_optimized_optimal_binary_search_tree.c`](../../../c/k/knuth_optimized_optimal_binary_search_tree.c) |
| C3 | [`c3/k/knuth_optimized_optimal_binary_search_tree.c3`](../../../c3/k/knuth_optimized_optimal_binary_search_tree.c3) |
| C++ | [`cpp/k/knuth_optimized_optimal_binary_search_tree.cpp`](../../../cpp/k/knuth_optimized_optimal_binary_search_tree.cpp) |
| Elisa | [`elisa/k/knuth_optimized_optimal_binary_search_tree.elisa`](../../../elisa/k/knuth_optimized_optimal_binary_search_tree.elisa) |
| Mojo | [`mojo/k/knuth_optimized_optimal_binary_search_tree.mojo`](../../../mojo/k/knuth_optimized_optimal_binary_search_tree.mojo) |
| Nim | [`nim/k/knuth_optimized_optimal_binary_search_tree.nim`](../../../nim/k/knuth_optimized_optimal_binary_search_tree.nim) |
| Odin | [`odin/k/knuth_optimized_optimal_binary_search_tree.odin`](../../../odin/k/knuth_optimized_optimal_binary_search_tree.odin) |
| Rust | [`rust/k/knuth_optimized_optimal_binary_search_tree.rs`](../../../rust/k/knuth_optimized_optimal_binary_search_tree.rs) |
| V | [`v/k/knuth_optimized_optimal_binary_search_tree.v`](../../../v/k/knuth_optimized_optimal_binary_search_tree.v) |
| Zig | [`zig/k/knuth_optimized_optimal_binary_search_tree.zig`](../../../zig/k/knuth_optimized_optimal_binary_search_tree.zig) |
