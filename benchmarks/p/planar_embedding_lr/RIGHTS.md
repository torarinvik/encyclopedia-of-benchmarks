# Rights and provenance

This package uses the mathematical method described by Ulrik Brandes in
[“The Left-Right Planarity Test”](https://www.uni-konstanz.de/algo/publications/b-lrpt-sub.pdf).
The NetworkX 3.7 [planarity implementation](https://github.com/networkx/networkx/blob/networkx-3.7/networkx/algorithms/planarity.py)
was also consulted as a secondary description of the same method. Both sources
are cited for algorithm study only; the package does not reproduce their text,
figures, pseudocode, or source code.

NetworkX is distributed under the [BSD 3-Clause License](https://github.com/networkx/networkx/blob/networkx-3.7/LICENSE.txt).
No NetworkX implementation code is included or translated in this package.

The [Library Checker planar-embedding proposal #1426](https://github.com/yosupo06/library-checker-problems/pull/1426)
is a task-discovery and output-contract reference only. Its implementation,
checker, test data, and problem statement are not used. The workload fixtures
are independently specified small graphs. All package code and documentation
are clean-room authored.
