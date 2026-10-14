# Dijkstra shortest paths

Dijkstra finds shortest paths from one source when every edge weight is nonnegative. The checked upstream sources use different graph and frontier structures: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/dijkstra.c) uses an adjacency matrix and selects the next minimum vertex, [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/dijkstra.cpp) uses a priority queue, and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/dijkstra.rs) uses an ordered set. The local benchmark standardizes the result and uses one caller-owned flat edge list across all nine languages.

## Interface and contract

```c
int64_t dijkstra(const int64_t *edges,
                 size_t vertices, size_t edge_count, size_t source,
                 int64_t *distances, uint8_t *reachable);
```

`edges` is a flat sequence of `edge_count` directed triples `(origin, destination, weight)`. Endpoints and weights are signed 64-bit integers. The caller provides room for `3 * edge_count` edge values, `vertices` distances, and `vertices` reachability bytes. Buffers must be valid, large enough, and mutually disjoint. Any zero-length buffer may be null. The implementation does not allocate memory.

Every edge weight must be nonnegative, including edges unreachable from the source. An empty graph succeeds only when `vertices`, `edge_count`, and `source` are all zero. Otherwise, the source and every endpoint must be in `[0, vertices)`. The function checks the source first, then checks each edge in input order; for each edge, endpoints are checked before its weight. This makes malformed-input status deterministic.

| Result | Meaning |
| ---: | --- |
| `0` | Success. |
| `-2` | Adding a reachable edge weight would overflow signed 64-bit distance storage. |
| `-3` | Invalid source, endpoint, or empty-graph shape. |
| `-4` | Negative edge weight. |

On success, `reachable[v]` is `1` exactly when a path exists from the source. `distances[v]` contains the exact shortest distance for reachable vertices and zero for unreachable vertices. The separate flag lets `INT64_MAX` be a valid finite distance. On error, output buffers are unspecified.

The ports select the lowest-distance unprocessed vertex, then scan the flat edge list for its outgoing edges. They use the reachability byte temporarily to track unseen, pending, and processed vertices, then normalize it to `0` or `1` before returning. This shared no-allocation variant takes `O(V(V + E))` time in the worst case and constant auxiliary storage. An overflowing sum returns `-2` whenever it is evaluated from a reachable processed vertex, even if it would not improve the destination's current distance.

## Workload and timing

[`workload.json`](workload.json) contains 32 cases for empty and singleton graphs, disconnected components, ties, parallel edges, zero weights, self loops, nonzero sources, negative weights, invalid vertices, `INT64_MAX` distances, addition overflow, and dense and sparse graphs. Successful cases give one expected distance per vertex and use JSON `null` for unreachable vertices.

The portable C11 harness parses each graph and allocates guarded buffers before timing. It checks the full distance and reachability vectors after each batch, verifies input immutability and canaries, and times only repeated algorithm calls with C `clock()` process CPU time.

## Build and verify

Build an implementation and its graph harness with the shared recipe:

```sh
python3 benchmarks/build_abi.py --family shortest_path --algorithm dijkstra --language c
```

Record the published workload using the build manifest:

```sh
python3 benchmarks/run_shortest_path.py \
  --build-manifest build/shortest_path/d/dijkstra/c/build.json
```

Check all nine ports against the independent heap-based oracle with:

```sh
python3 benchmarks/verify_dijkstra.py \
  --elisa-compiler /absolute/path/to/elisac
```

The verifier checks the published cases, exhaustive small directed graphs, deterministic random graphs, reversed edge orders, negative weights, invalid endpoints, and signed 64-bit boundaries. Its report is written to `build/dijkstra/verification.json`. The one-sample records created during verification validate correctness and the recorder format; they are not performance comparisons.
