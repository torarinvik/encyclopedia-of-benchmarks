# Optimal binary search tree

This benchmark computes the minimum weighted search cost for an ordered sequence of BST keys. If a key has frequency `f` and depth `d` with the root at depth 1, its contribution is `f*d`. The recurrence chooses each key in a range as root, adds the range's total frequency, and combines the left and right subproblem costs.

Input is `[key_count, frequency_0, ...]`, with 1–32 keys in ascending key order and frequencies 0–1000. The ordered frequency list represents the frequencies after sorting the associated Java keys; the Rust and Go sources already consume frequencies in this order. The returned scalar is the minimum total weighted search cost. Invalid input returns `-1`. See `optimal_binary_search_tree_oracle.py` for the runtime oracle.
