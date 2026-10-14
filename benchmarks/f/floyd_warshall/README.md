# Floyd–Warshall shortest paths

This benchmark computes all-pairs shortest paths in a directed weighted graph, then returns the distance row for one requested source. The ports follow the Floyd–Warshall recurrence and use a fixed, bounded matrix so implementations need no architecture-specific features or dynamic allocation.

## Contract

- Input is a directed list of `(origin, destination, weight)` triples with signed 64-bit weights and between 1 and 64 vertices. Duplicate edges use their minimum weight. The diagonal starts at zero; all other pairs start unreachable.
- The implementation evaluates the recurrence in middle-vertex, origin, destination order. On success it returns `0` and writes one distance per destination. Reachability is a separate byte flag; unreachable distances are stored as zero.
- A source that is out of range, an invalid endpoint, an invalid empty graph, or more than 64 vertices returns `-3`. A negative cycle reachable from the requested source returns `-1`. If any finite-pair addition overflows signed 64-bit range while the all-pairs recurrence is running, the function returns `-2`.
- A negative cycle in a disconnected component does not invalidate the requested source row. Invalid calls leave output buffers unspecified.

The ports use a fixed 64 by 64 matrix, perform `O(V^3)` work, and use portable scalar arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton graphs, negative and parallel edges, disconnected components, reachable and unreachable negative cycles, signed overflow, invalid vertices, and a sparse graph at the 64-vertex limit. [`benchmarks/verify_floyd_warshall.py`](../../verify_floyd_warshall.py) checks the workload, every small graph in its exhaustive 2- and 3-vertex corpus, deterministic random graphs, reversed edge orders, overflow cases, and the maximum graph size across all nine languages.

## Build

```sh
python3 benchmarks/build_abi.py --family shortest_path --algorithm floyd_warshall --language c
python3 benchmarks/verify_floyd_warshall.py --elisa-compiler /absolute/path/to/elisac
```

## Reviewed TheAlgorithms sources

- [C `floyd_warshall.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/floyd_warshall.c), [C++ `floyd_warshall.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/floyd_warshall.cpp), and [Rust `floyd_warshall.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/floyd_warshall.rs) provide the reviewed references. Their graph representations and output APIs differ; this benchmark normalizes them to the same bounded edge-list and source-row contract.
