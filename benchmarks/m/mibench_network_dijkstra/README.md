# MiBench queue-based network shortest paths

This package preserves the pinned MiBench `network-dijkstra` routine's FIFO
label-correcting method. Its queue processes labels in arrival order and
re-enqueues a vertex on each strict improvement. The existing [`dijkstra`](../../d/dijkstra/README.md)
package is label-setting: it repeatedly selects the lowest tentative-distance
vertex. These are distinct shortest-path algorithms even though both produce
single-source distances on the bounded nonnegative-weight domain. The local
[`bellman_ford`](../../b/bellman_ford/README.md) instead scans the full edge
list for each pass; this source uses a FIFO work queue and queued distance
snapshots.

## Contract

- ABI: `i64_array_scalar`, symbol `mibench_network_dijkstra`.
- Input is `[node_count, source, costs...]`, followed by a row-major directed
  adjacency matrix. `node_count` is from 1 through 6, and `source` is in
  `[0,node_count)`. A matrix entry of `9999` means no edge; present edge costs
  range from 0 through 31.
- The FIFO queue stores each enqueued node and its queued distance. Popped
  entries scan destination indices in ascending order. Stale entries are
  processed as the source does; each strict improvement appends another entry.
- The scalar result is `sum((node_index+1)*distance)` over reachable nodes,
  plus a bit mask of reachable node indices. This summarizes the full
  single-source result, including zero-distance and unreachable vertices.
- Invalid framing, source indices, and costs return `-1`. The bounded queue
  guard returns `-2`; the selected graph and weight bounds keep valid cases
  within the fixed capacity.

The independent [oracle](../../mibench_network_dijkstra_oracle.py) uses a
separate Python deque implementation of the queue relaxation. The workload
includes path improvements that re-enqueue a vertex, a zero-weight cycle,
unreachable vertices, and invalid framing and values.

## Provenance and license

The pinned launcher compiles `dijkstra.c` with `-lm` and reads `input.dat`.
Its `LICENSE` file says “It is GPL'ed” but does not name a GPL version; this
package records that statement without inferring a version. The ports are
independently written from the observed queue and relaxation behavior.

- [`dijkstra.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/dijkstra.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/info.sh)
- [`LICENSE`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/LICENSE)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/d/mibench_network_dijkstra.c](../../../c/d/mibench_network_dijkstra.c) |
| C3 | [c3/d/mibench_network_dijkstra.c3](../../../c3/d/mibench_network_dijkstra.c3) |
| C++ | [cpp/d/mibench_network_dijkstra.cpp](../../../cpp/d/mibench_network_dijkstra.cpp) |
| Elisa | [elisa/d/mibench_network_dijkstra.elisa](../../../elisa/d/mibench_network_dijkstra.elisa) |
| Nim | [nim/d/mibench_network_dijkstra.nim](../../../nim/d/mibench_network_dijkstra.nim) |
| Odin | [odin/d/mibench_network_dijkstra.odin](../../../odin/d/mibench_network_dijkstra.odin) |
| Rust | [rust/d/mibench_network_dijkstra.rs](../../../rust/d/mibench_network_dijkstra.rs) |
| V | [v/d/mibench_network_dijkstra.v](../../../v/d/mibench_network_dijkstra.v) |
| Zig | [zig/d/mibench_network_dijkstra.zig](../../../zig/d/mibench_network_dijkstra.zig) |
