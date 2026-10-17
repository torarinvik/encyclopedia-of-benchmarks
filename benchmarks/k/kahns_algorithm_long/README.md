# Kahn's algorithm for longest DAG path

## Contract

This benchmark extracts the topological dynamic program in the pinned Python `kahns_algorithm_long.py`. Each vertex starts with distance 1, and every directed edge `u -> v` propagates `distance[v] = max(distance[v], distance[u] + 1)`. The result is the largest path length measured in vertices. The source's hard-coded graph and print statement are replaced by a bounded input array and scalar return value.

The `i64_array_scalar` input is `[vertex_count, edge_count, from_0, to_0, ..., from_(m-1), to_(m-1)]`. It explicitly declares 1..32 vertices, including isolated vertices; it accepts 0..128 directed edges, including parallel edges. Endpoints must be in `0..vertex_count-1`, the packed input length must be exact, and the graph must be acyclic. Invalid input, a null pointer, or a cyclic graph returns `-1`.

## Workload

[`workload.json`](workload.json) covers the pinned example graph, chains, branching and disconnected DAGs, isolated vertices, parallel edges, input boundaries, malformed arrays, and cycles.

## TheAlgorithms reference

- Python [`kahns_algorithm_long.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/kahns_algorithm_long.py) uses Kahn's queue to propagate longest distances in vertices, then prints their maximum.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/k/kahns_algorithm_long.c](../../../c/k/kahns_algorithm_long.c) |
| C3 | [c3/k/kahns_algorithm_long.c3](../../../c3/k/kahns_algorithm_long.c3) |
| C++ | [cpp/k/kahns_algorithm_long.cpp](../../../cpp/k/kahns_algorithm_long.cpp) |
| Elisa | [elisa/k/kahns_algorithm_long.elisa](../../../elisa/k/kahns_algorithm_long.elisa) |
| Nim | [nim/k/kahns_algorithm_long.nim](../../../nim/k/kahns_algorithm_long.nim) |
| Odin | [odin/k/kahns_algorithm_long.odin](../../../odin/k/kahns_algorithm_long.odin) |
| Rust | [rust/k/kahns_algorithm_long.rs](../../../rust/k/kahns_algorithm_long.rs) |
| V | [v/k/kahns_algorithm_long.v](../../../v/k/kahns_algorithm_long.v) |
| Zig | [zig/k/kahns_algorithm_long.zig](../../../zig/k/kahns_algorithm_long.zig) |
