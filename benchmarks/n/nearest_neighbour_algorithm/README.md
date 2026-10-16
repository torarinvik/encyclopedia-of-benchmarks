# Nearest neighbour algorithm

Implements the pinned Dart `nearestNeighbourSearch` greedy walk on a weighted adjacency matrix. It starts at node zero, selects the least-weight edge to an unvisited node, and breaks ties by choosing the first unvisited node in input order. The result is the order of visited node indices.

The `i64_array_bytes_output` ABI accepts `[node_count, row-major adjacency matrix...]` for 1–16 nodes with nonnegative weights at most 1,000,000. The output is zero-based indices joined by commas. The benchmark restricts weights to integers to avoid cross-language floating-point tie differences; directed matrices are accepted, as the source consults the current node's row.

Invalid input returns `-1`; insufficient output capacity returns `-2`. `nearest_neighbour_algorithm_oracle.py` is the runtime expected-output oracle.
