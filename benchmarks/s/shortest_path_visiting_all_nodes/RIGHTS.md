# Rights and provenance

This package is a clean-room implementation of an unweighted graph-walk
benchmark. Its discovery lead is the official public title of LeetCode 847;
the repository uses no challenge statement, examples, tests, submissions, or
site code. The algorithm contract is stated independently in this package.

The primary product-state breadth-first search is based on the general BFS
method described by [CP-Algorithms](https://cp-algorithms.com/graph/breadth-first-search.html).
The independent verifier uses the standard all-pairs shortest-path closure
and subset dynamic programming; see [Floyd–Warshall on CP-Algorithms](https://cp-algorithms.com/graph/all-pair-shortest-path-floyd-warshall.html).
These pages are algorithm references only. No source code or prose was copied.

The package-owned Python oracles and language ports are dedicated to this
repository under the repository's project license. CP-Algorithms material is
CC BY-SA 4.0; it is used only to identify the mathematical methods. The
LeetCode title is used only as a public discovery label.
