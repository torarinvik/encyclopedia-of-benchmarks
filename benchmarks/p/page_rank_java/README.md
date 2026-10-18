# PageRank (Java variant)

This package covers the pinned Java `PageRank.calculatePageRank` implementation. Its update uses a per-node teleport term of `(1-d)` and does not redistribute rank from dangling nodes. Python and Rust use `(1-d)/n` and redistribute dangling mass, so those implementations are benchmarked under the separate `page_rank` contract.

## Contract

The `float64_slice_io` input is `[node_count, iteration_count, row-major adjacency_matrix...]`, with row `i`, column `j` representing edge `i -> j`. Node IDs are `0..n-1` in the workload and map to the Java source's 1-based matrix indices. The bounds are 1–4 nodes, 1–8 iterations, binary matrix entries, and zero diagonal. Damping is fixed at `0.5`.

Initialize each rank to `1/n`. For each iteration, sum each incoming source's previous rank divided by its outgoing degree, then set target rank to `(1-d) + d*incoming_sum`. A source with no outgoing edges contributes nothing. Output the first `n` Java rank slots in node order. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.

See the [workload](workload.json), [oracle](../../page_rank_java_oracle.py), and pinned [`PageRank`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/PageRank.java).
