# PageRank (Python and Rust variant)

This package covers the pinned Python and Rust PageRank implementations. Those sources redistribute dangling-node rank and apply the teleport share `(1-d)/n`. Rust deduplicates repeated neighbors, so the shared graph contract uses a simple directed graph. Java uses a different teleport term and is covered by the separate `page_rank_java` package.

## Contract

The `float64_slice_io` input is `[node_count, iteration_count, adjacency_matrix...]`, with a row-major matrix where row `i`, column `j` represents edge `i -> j`. Node IDs are `0..node_count-1`. The bounds are 2–4 nodes, 0–8 iterations, binary matrix entries, and no self-loops. Every node is included as a source row, including nodes with no outgoing edges. The damping factor is fixed at `0.5`, and the convergence threshold is fixed at `0.0`, so the source executes exactly the supplied iteration count.

Initialize every rank to `1/n`. At each iteration, sum the ranks of zero-outdegree nodes, then update every node with `(1-d)/n + d * (incoming rank share + dangling rank share)`. Each outgoing edge contributes `rank[source]/outdegree[source]`. The oracle accumulates sources in ascending node order; Rust's hash iteration can change only floating-point summation order, and the workload compares with `1e-12` absolute and relative tolerance. Output is the rank vector in node ID order. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.

See the [workload](workload.json), [oracle](../../page_rank_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/page_rank.py) and [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/page_rank.rs).
