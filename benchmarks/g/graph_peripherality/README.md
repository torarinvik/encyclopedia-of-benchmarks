# Graph peripherality and farness

This benchmark computes a graph's peripheral node (maximum eccentricity) and far node (maximum farness) using the pinned Python source's directed all-pairs shortest-path calculations.

## Contract

- Input is `[node_count, edge_count, (source, destination, weight)...]` as signed 64-bit integers. `node_count` is 1 through 8, vertex IDs are the contiguous integers `0..node_count-1`, and edge weights are positive integers from 1 through 1,000,000.
- For `node_count > 1`, the directed graph must be strongly connected. Graphs are simple and loopless: duplicate directed edges and self-loops are invalid. The one-vertex graph has no edges and returns node 0 with both metrics zero.
- Floyd–Warshall computes shortest paths. A vertex's eccentricity is its maximum shortest-path distance to any other vertex; its farness is the sum of those distances. The peripheral node maximizes eccentricity; the far node maximizes farness. Ties select the lowest vertex ID.
- Invalid input, including a disconnected graph with more than one vertex, returns `-1`. Missing or insufficient output storage returns `-2` without writing. Output is four little-endian signed 64-bit integers: `[peripheral_node, eccentricity, far_node, farness]`.

The connected-domain restriction avoids the pinned source's `+infinity` behavior for vertices with no reachable peers and makes all metric outputs finite. Bounded positive integer weights keep all shortest-path sums exactly representable.

[`workload.json`](workload.json) covers a singleton, a weighted strongly connected graph, a lowest-ID tie, disconnected and all-isolated invalid graphs, and invalid weights. Record measurements with [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py).

## Pinned source

- [TheAlgorithms/Python `graph_peripherality.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_peripherality.py)
