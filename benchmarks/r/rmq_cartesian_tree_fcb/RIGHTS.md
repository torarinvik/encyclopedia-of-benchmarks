# Rights and provenance

The composed algorithm follows CP-Algorithms' article [Solve RMQ by finding
LCA](https://cp-algorithms.com/graph/rmq_linear.html), which is licensed under
CC BY-SA 4.0. The article describes a min Cartesian tree, the equivalence
between a range minimum and the LCA of its endpoint nodes, and the
Farach–Colton–Bender Euler-tour RMQ method. The ports, bounded ABI, workload,
references, and prose are independently authored from the algorithm
description. No source code, article text, or upstream test data was copied.

Distinctness note: [`cartesian_tree`](../../c/cartesian_tree/README.md) emits
the tree but does not answer range queries; the FCB LCA package
([`lowest_common_ancestor_farach_colton_bender`](../../l/lowest_common_ancestor_farach_colton_bender/README.md))
accepts an explicit tree but does not build one from an array. This benchmark
measures their composed static RMQ operation and returns exact leftmost-minimum
indices. Sparse tables, Sqrt Tree, and Arpa offline RMQ use different RMQ
kernels.
