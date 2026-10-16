# Graph density

This benchmark follows the pinned JavaScript `density(numberOfNodes, numberOfEdges, isDirected)` function. It returns the fraction of possible edges that are present:

```text
factor = directed ? 1 : 2
density = (factor * edge_count) / (node_count * (node_count - 1))
```

The operation order matches the source. For an undirected simple graph, each edge is counted once while the denominator counts both orientations, hence the factor of two. For a directed simple graph, the source uses factor one.

## Contract

- Pack exactly `[node_count, edge_count, directed_flag]` as signed 64-bit integers.
- `node_count` is in `2..=100000`; `directed_flag` is `0` for undirected or `1` for directed.
- `edge_count` is in `0..=n*(n-1)/2` for undirected graphs and `0..=n*(n-1)` for directed graphs.
- Return the formula result as binary64. Malformed or out-of-domain input returns `-1e300`.

The source does not guard the zero denominator at node counts zero or one, so those inputs are outside the benchmark domain. The upper node bound keeps the integer numerator and denominator below 2^53, preserving exact integer products in JavaScript's binary64 arithmetic. The graph edge bounds describe simple graphs; the source itself accepts its arguments without checking graph structure.

This is graph density, distinct from physical density calculations and from a weighted graph's edge representation. See [`workload.json`](workload.json) for directed and undirected cases, complete/empty graphs, and invalid inputs.

## Source

- [TheAlgorithms/JavaScript `Density.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/Density.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

Verify the bounded package with `python3 benchmarks/verify_i64_array_float64.py --algorithm density`.
