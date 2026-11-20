# Rights and provenance

LeetCode 1293, Shortest Path in a Grid with Obstacles Elimination, was used as
a public title-index discovery source: https://leetcode.com/problems/shortest-path-in-a-grid-with-obstacles-elimination/.
The implementation profile is a bounded clean-room formulation. The grid is
expanded into unweighted states containing both a cell and remaining removal
budget; BFS is used because every transition costs one step. The independent
reference relaxes all product-graph transitions repeatedly.

The standard unweighted shortest-path property is cross-checked against
CP-Algorithms' breadth-first search reference:
https://cp-algorithms.com/graph/breadth-first-search.html.

No LeetCode statement, examples, editorial, tests, submissions, or code were
copied. No CP-Algorithms code or prose was copied. The bounded input contract,
fixtures, references, ports, and documentation were written specifically for
this benchmark.
