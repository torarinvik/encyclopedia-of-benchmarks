# Rights and provenance

The algorithmic idea comes from the “Binary Grouping Optimization” section of
CP-Algorithms' [`Knapsack Problem`](https://cp-algorithms.com/dynamic_programming/knapsack.html#binary-grouping-optimization).
The article is published under CC BY-SA 4.0. Only the mathematical method was
consulted; no source code, examples, fixtures, or prose are reproduced.

The package code and workloads are clean-room. Its primary reference groups
each multiplicity into disjoint powers-of-two bundles and performs descending
0/1 capacity updates. The independent reference instead enumerates each
item type's allowed copy count in a fresh DP row.
