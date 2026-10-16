# Graph Centrality

This benchmark computes the central node and harmonic-closeness median of a weighted directed graph. It follows the Python source’s Floyd–Warshall all-pairs shortest paths and its centrality calculations; it does not benchmark graph traversal.

## Contract

- Input is `[node_count, edge_count, (source, destination, weight)...]` as signed 64-bit integers. There are 1–16 nodes, node indices are zero-based, and every directed edge has a positive integer weight from 1 through 1,000,000.
- The graph is loopless and has at most one edge for each ordered node pair. The encoded edge count must match the input length. These bounds keep path sums within signed 64-bit range and make the weighted domain identical across the nine ports.
- The central node minimizes its maximum shortest-path distance to other reachable nodes. The harmonic median maximizes the sum of reciprocal shortest-path distances to reachable nodes. Unreachable nodes do not contribute; ties select the lowest node index.
- A single-node graph returns node `0` for both results. If no node can reach another node, both results are `-1`.
- Output is two little-endian signed 64-bit node indices, central first and harmonic median second. The function returns 16 bytes, `-1` for malformed input, or `-2` when output storage is missing or too small.

The pinned source uses NumPy floating-point distances and accepts positive floating-point edge weights. This portable contract uses bounded integer weights and excludes self-loops and duplicate arcs, which the source’s matrix assignment would otherwise overwrite.

[`workload.json`](workload.json) includes single-node, directed, symmetric, disconnected, all-isolated, tie-breaking, duplicate-edge, and zero-weight cases. Record measurements with [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py).

## Pinned source

- [TheAlgorithms/Python `graph_centrality.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_centrality.py)
