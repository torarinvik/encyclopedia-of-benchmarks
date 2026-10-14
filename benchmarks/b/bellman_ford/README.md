# Bellman–Ford shortest paths

Bellman–Ford finds shortest paths from one source in a directed, weighted graph. It accepts negative edge weights and reports a negative cycle only when that cycle is reachable from the source. The inspected upstream implementations include [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/bellman_ford.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/bellman_ford.cpp), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/bellman_ford.rs). Their graph representations, integer widths, and result conventions differ, so the benchmark defines one explicit C ABI and graph contract for all nine languages.

## Interface and contract

```c
int64_t bellman_ford(const int64_t *edges,
                     size_t vertices, size_t edge_count, size_t source,
                     int64_t *distances, uint8_t *reachable);
```

`edges` is a flat sequence of `edge_count` triples `(origin, destination, weight)`. Endpoints and weights are signed 64-bit integers. The caller provides space for `3 * edge_count` edge values, `vertices` distances, and `vertices` reachability bytes. The buffers must be valid, large enough, and mutually disjoint. Any zero-length buffer may be passed as null. The implementation does not allocate memory.

On success, the function returns `0`. For every vertex, `reachable[v]` is `1` exactly when a path from the source exists. `distances[v]` is the shortest signed 64-bit distance for reachable vertices and is set to `0` for unreachable vertices. Reachability is separate from the distance, so every signed 64-bit value, including both endpoints, can be a valid distance.

The error results are:

| Result | Meaning |
| ---: | --- |
| `-1` | A negative cycle is reachable from the source. |
| `-2` | Evaluating a reachable edge would overflow signed 64-bit addition. |
| `-3` | Invalid source, invalid edge endpoint, or invalid empty-graph shape. |

An empty graph succeeds only when `vertices`, `edge_count`, and `source` are all zero. For a nonempty graph, `source` must be less than `vertices`, and every edge endpoint must be in `[0, vertices)`. Endpoints are validated before any distance is calculated, including endpoints on unreachable edges. If several error conditions could occur, the implementation returns the first one encountered during its specified validation and edge traversal. In particular, an overflowing reachable edge returns `-2` even when its candidate distance could not improve the current result; overflow may therefore be reported before a negative cycle is established. Output buffers are unspecified when the function returns an error.

The implementation runs up to `vertices` edge-relaxation passes in input order. It stops early when a pass changes no distance. The final pass detects a reachable negative cycle. This takes `O(VE)` time in the worst case and uses no auxiliary storage beyond the caller's buffers.

## Workload and timing

[`workload.json`](workload.json) contains 31 fixed cases for empty and singleton graphs, disconnected components, negative and zero edges, negative cycles, parallel edges, nonzero sources, invalid inputs, signed 64-bit boundaries, overflow, and graphs whose edge order requires repeated passes. Successful cases list the expected distance for every vertex and use JSON `null` for unreachable vertices.

The benchmark ABI uses caller-owned buffers. The C11 harness allocates them and parses the graph before timing, validates all distances and reachability flags after each batch, and checks canaries and input immutability. Only the repeated algorithm calls are timed with `clock()` process CPU time. Error cases verify the returned status; output contents are intentionally ignored after an error.

## Build and verify

Build any implementation and its graph harness through the shared portable recipe:

```sh
python3 benchmarks/build_abi.py --family shortest_path --algorithm bellman_ford --language c
```

Record the published workload with the matching build manifest:

```sh
python3 benchmarks/run_shortest_path.py \
  --build-manifest build/shortest_path/b/bellman_ford/c/build.json
```

Run the independent all-language correctness check with:

```sh
python3 benchmarks/verify_shortest_path.py \
  --elisa-compiler /absolute/path/to/elisac
```

The verifier compares the C ABI results with an arbitrary-precision Floyd–Warshall oracle. It checks every published case, exhaustive small directed graphs, deterministic random graphs, reversed edge orders, and integer-boundary cases. Its report is written to `build/shortest_path/verification.json`; the one-sample result records made during verification check the recorder format and are not performance comparisons.
