# Olden EM3D node update

This package captures the node-update kernel from the pinned Olden EM3D
benchmark. It updates one bipartite electric/magnetic graph in place: all E
nodes are processed in order from H values, followed by all H nodes in order
from the newly updated E values. This is distinct from the local Maxwell
formula calculators and bipartite matching algorithms.

## Contract

The `float64_slice_io` symbol is `olden_em3d`. Input is
`[node_count, degree, E_values..., H_values..., E_neighbor_ids...,
E_coefficients..., H_neighbor_ids..., H_coefficients...]`. There are 1–8 nodes
per partition and degree 1–4. Each node has exactly `degree` distinct incoming
neighbors from the other partition. Initial values, edge coefficients, and
neighbor IDs are bounded to `[0,1]` and `[0,node_count-1]` respectively.

For each node, start from its current value and subtract
`coefficient[j] * source_value[neighbor[j]]` in edge order. The pinned C source
uses the coefficient at the even edge index for both members of each pair;
the local contract preserves this observable behavior, including the final
odd edge. E nodes are updated sequentially first, then H nodes consume the
updated E values. The output is all E values followed by all H values.
Malformed input returns `-1`; a null output or insufficient capacity returns
`-2` without writing. Comparison tolerance is absolute and relative `1e-12`.

The bounded package isolates `compute_nodes` and supplies the graph explicitly.
It omits upstream `drand48` graph generation, processor partitioning, and
launcher-scale default values of 1,024 nodes, degree 1,000, and 125% local-edge
setting (the small profile uses 256, 250, and 35). See
[`workload.json`](workload.json) and the independent
[`olden_em3d_oracle`](../../olden_em3d_oracle.py).

## Pinned source and license

- [`em3d.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/em3d/em3d.c)
- [`make_graph.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/em3d/make_graph.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/em3d/info.sh)

The pinned source headers refer to `olden_v1.0/COPYRIGHT`, which is not
available at the referenced path in this snapshot. The ports are independently
written and no license is inferred.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/o/olden_em3d.c](../../../c/o/olden_em3d.c) |
| C3 | [c3/o/olden_em3d.c3](../../../c3/o/olden_em3d.c3) |
| C++ | [cpp/o/olden_em3d.cpp](../../../cpp/o/olden_em3d.cpp) |
| Elisa | [elisa/o/olden_em3d.elisa](../../../elisa/o/olden_em3d.elisa) |
| Nim | [nim/o/olden_em3d.nim](../../../nim/o/olden_em3d.nim) |
| Odin | [odin/o/olden_em3d.odin](../../../odin/o/olden_em3d.odin) |
| Rust | [rust/o/olden_em3d.rs](../../../rust/o/olden_em3d.rs) |
| V | [v/o/olden_em3d.v](../../../v/o/olden_em3d.v) |
| Zig | [zig/o/olden_em3d.zig](../../../zig/o/olden_em3d.zig) |
