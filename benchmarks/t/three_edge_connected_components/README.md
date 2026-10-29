# Three-edge-connected components

This benchmark computes the vertex classes that remain connected after every removal of zero, one, or two edge IDs from a bounded undirected multigraph. It accepts loops and parallel edge instances; each input edge position is a separate ID. The output is normalized because the official task permits component IDs in arbitrary order.

## Contract

- Input is `[n, m, (u, v)...]`, with vertices numbered `0..n-1` and edge endpoints packed in input order.
- `n` is 1–8 and `m` is 0–32. Loops and repeated endpoint pairs are valid. Every endpoint must be in range and the input length must equal `2 + 2m`.
- Two vertices share a component exactly when they remain connected after removing any set of at most two edge IDs, including the empty set.
- Canonical labels are assigned by scanning vertices in ascending order: each component receives the next integer when its smallest vertex is first encountered.
- The result encodes the labels as base-8 digits: `Σ(label[v] * 8^v)`. Invalid framing, limits, or endpoints return `-1`.

The bounded implementations enumerate the empty removal, every single edge ID, and every unordered pair of distinct edge IDs. For each case they run a graph traversal, then refine the pairwise same-component relation. With `D = 1 + m + m(m-1)/2` removal cases, the ports use `O(D(nm+n²))` time when each traversal scans the small edge list and `O(n²+n+m)` auxiliary space. The limits keep this direct definition executable while preserving edge-instance semantics for loops and parallel edges.

[`workload.json`](workload.json) covers isolated vertices, bridges, parallel edges, loops, a triangle, complete and edge-deficient graphs, disconnected 3-edge-connected groups, malformed input, and a null-input probe. [`benchmarks/three_edge_connected_components_oracle.py`](../../three_edge_connected_components_oracle.py) independently enumerates edge-removal sets and performs direct reachability searches. [`benchmarks/verify_three_edge_connected_components.py`](../../verify_three_edge_connected_components.py) statically checks the workload, oracle results, provenance, and all nine source paths; it does not compile or execute the ports.

## Source

- [Library Checker: Three-Edge-Connected Components](https://judge.yosupo.jp/problem/three_edge_connected_components) supplies the graph-problem taxonomy. Its component output ordering is arbitrary, so this benchmark defines canonical labels and a scalar encoding for cross-language comparison.

## Implementations

All nine ports use the shared `i64_array_scalar` ABI. Their files are in the `t` directory for `c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`.
