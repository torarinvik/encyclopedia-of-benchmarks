# Tree matching

Compute a maximum weight matching in a weighted undirected tree, rooted at the supplied vertex. This ports the dynamic program in [TheAlgorithms Java `TreeMatching.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/TreeMatching.java). For each node, the algorithm stores the best matching when it is not paired with a child and the best matching when it is paired with exactly one child. The result is the larger value at the root.

The `i64_array_scalar` ABI packs the input as `[node_count, root, (u, v, weight)...]`. Vertices are zero-based, and each edge is undirected. Edge weights are nonnegative, matching the source problem's natural-number weights.

## Bounds and invalid inputs

- `1 <= node_count <= 64`; the input contains exactly `node_count - 1` edge triples.
- The largest valid or parseable input contains 191 signed 64-bit values (`2 + 3 * 63`).
- `root` and all endpoints must be in `0..node_count-1`. Self-edges, duplicate undirected edges, cycles, and disconnected graphs are invalid.
- `0 <= weight <= 1000`. The largest possible answer is 32,000, so it fits in the source's signed `int` and in the ABI result.
- Invalid packed input returns `-1`.

The workload uses the `i64_array_scalar` ABI and `i64_array_scalar_call` comparison model.
