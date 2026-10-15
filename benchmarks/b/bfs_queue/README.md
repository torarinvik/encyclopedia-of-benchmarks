# BFS queue shortest path

This benchmark uses a FIFO queue to search an undirected graph from a source to one target. It stores a predecessor for each discovered vertex and stops as soon as it discovers the target, so it returns a shortest path rather than the full traversal order of [`breadth_first_search`](../breadth_first_search/README.md).

## Contract

- Input is `[vertex_count, source, target, edge_count, (left, right) * edge_count]` with zero-based vertex IDs.
- There are 1–64 vertices and 0–2,046 undirected edges. Endpoints must be valid. Repeated and self-edges are allowed; repeated edges are coalesced.
- The packed input must have exactly `4 + 2 * edge_count` values. Invalid input returns `-1`.
- The output begins with a found flag byte. If a path exists, the flag is `1` and the remaining bytes list the path in destination-to-source order, matching the pinned C example's reconstruction loop. If no path exists, the output is the single byte `0`.
- The result is the number of output bytes. If the buffer is too small, return `-2` without writing output.
- Equal source and target use the conventional trivial path: `[1, source]`. The pinned C helper returns false for this case because it only tests newly discovered neighbors; this benchmark fixes that missing special case.

Neighbors are considered in ascending vertex ID order. That makes the selected shortest path deterministic when multiple shortest paths exist. The ports use fixed-size arrays and an adjacency bitset.

## Workload

[`workload.json`](workload.json) covers shortest paths, equal-length alternatives, unreachable targets, equal source/target, duplicate and self-edges, maximum vertex and edge bounds, and malformed inputs. Runtime verification is pending.

Build and record with the `i64_array_bytes_output` ABI family.

## Upstream source

- [TheAlgorithms/C BFS queue path source at the pinned revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/bfs_queue.c)
