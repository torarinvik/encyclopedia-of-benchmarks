# Constrained shortest path

This benchmark follows the pinned Java resource-constrained shortest-path solver. The state is indexed by the total resource consumed and the current node. It initializes cost zero at `(resource=0, start)`, scans resource totals in ascending order, then nodes in ascending order, and relaxes each outgoing edge when the new resource total stays within the limit. The answer is the minimum cost to the target across all resource totals, or `-1` when no feasible route exists. The source returns only a cost; it does not reconstruct a route.

## Contract

- Pack signed 64-bit integers as `[n, m, start, target, R, (from, to, cost, resource)*m]`, with exactly `5 + 4*m` values.
- `n` is in `1..=16`, `m` in `0..=64`, `R` in `0..=32`; start, target, and edge endpoints are zero-based node indices in `0..n`.
- Edge costs are in `0..=1000`. Each edge resource is in `1..=32`. The source ignores a transition if the cumulative resource would exceed `R`.
- Return the minimum feasible cost as a signed 64-bit integer, or `-1` when no feasible path exists. Malformed or out-of-domain packing returns `-2`.

The pinned method permits zero-resource edges, but its in-place resource-layer traversal may update a state in the same layer after that node has already been scanned. This benchmark requires strictly positive edge resources, so every transition goes to a later layer and the source's node-order update effects cannot change the result. Costs and resources keep all accumulated costs bounded and avoid Java `int` overflow.

This differs from ordinary shortest-path algorithms: each edge consumes a limited resource in addition to adding its path cost. See [`workload.json`](workload.json) for constrained alternatives, an unreachable target, the start-equals-target case, and invalid input.

## Source

- [TheAlgorithms/Java `ConstrainedShortestPath.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/ConstrainedShortestPath.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

Build and verify with the shared scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm constrained_shortest_path --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/constrained_shortest_path/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms constrained_shortest_path
```
