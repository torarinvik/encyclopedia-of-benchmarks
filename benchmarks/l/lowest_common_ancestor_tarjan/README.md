# Lowest Common Ancestor with Tarjan's Offline Algorithm

This benchmark answers a batch of lowest-common-ancestor queries on one rooted, undirected tree. It represents vertices by stable zero-based IDs, so duplicate values or node identities cannot make results ambiguous.

## Contract

- The packed input is `[node_count, root, edge_count, query_count, edges..., queries...]`. Each edge and query is a pair of zero-based vertex IDs. Edges are undirected; queries are answered in their original order.
- There are 1–256 vertices, exactly `node_count - 1` edges, and 0–1,024 queries. The root and every endpoint must be in range. The edge list must be a connected, acyclic tree, and the packed input must have exactly `4 + 2 * edge_count + 2 * query_count` values.
- Return one output byte per query, containing that query's LCA vertex ID. `(v, v)` returns `v`. A batch with no queries returns zero and writes no bytes.
- Invalid input returns `-1`. If the output buffer cannot hold all query answers, return `-2` without writing output.

The ports use Tarjan's offline algorithm: a depth-first traversal marks completed vertices, unions each completed child into its parent, and uses the disjoint-set representative's stored ancestor to answer queries once the other endpoint has finished. The traversal uses an explicit stack; disjoint-set operations use path compression and rank.

## Workload

[`workload.json`](workload.json) covers arbitrary roots, self-queries, empty batches, paths, maximum vertex/query counts, and malformed trees and query IDs. Runtime verification is pending.

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.

## Upstream source

- [TheAlgorithms/Rust offline LCA source at the pinned revision](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/graph/lowest_common_ancestor.rs)
