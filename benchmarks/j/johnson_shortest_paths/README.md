# Johnson Shortest Paths

This package follows the pinned R [`johnson_shortest_paths.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/johnson_shortest_paths.r), which computes all-pairs shortest-path distances with Bellman-Ford potentials followed by Dijkstra from each vertex.

## Contract

The `i64_array_scalar` input is `[V, E, (u, v, weight)*]`. Require `1 <= V <= 32`, `0 <= E <= 256`, endpoints in `[1,V]`, integer weights in `[-32,32]`, and no negative-weight cycle. The input names every vertex in the range `1..V`, including isolated vertices. Parallel edges, self-edges, and unreachable pairs are allowed. Invalid shape, endpoint, weight, or negative cycle returns `-1`.

The ports initialize all Bellman-Ford potentials to zero, equivalent to the source's implicit zero-weight supersource, then reweight the graph and run Dijkstra from each vertex. The result is the low 63 bits of FNV-1a-64 over the row-major `V x V` distance values only, with no dimension prefix. Finite distances remain exact signed integers; each R `Inf` is represented by exactly `2^62`. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The pinned R file uses a linear-scan data-frame priority queue despite its complexity comment and runs a five-vertex demo at top level. The package preserves the distance behavior of `johnson_shortest_paths(graph)`; the demo output is scaffolding outside the function ABI. The independent oracle uses Floyd-Warshall in [`johnson_shortest_paths_oracle.py`](../../johnson_shortest_paths_oracle.py); workload cases are in [`workload.json`](workload.json).

## Implementations

| Language | Port |
|---|---|
| C | [`c/j/johnson_shortest_paths.c`](../../../c/j/johnson_shortest_paths.c) |
| C3 | [`c3/j/johnson_shortest_paths.c3`](../../../c3/j/johnson_shortest_paths.c3) |
| C++ | [`cpp/j/johnson_shortest_paths.cpp`](../../../cpp/j/johnson_shortest_paths.cpp) |
| Elisa | [`elisa/j/johnson_shortest_paths.elisa`](../../../elisa/j/johnson_shortest_paths.elisa) |
| Nim | [`nim/j/johnson_shortest_paths.nim`](../../../nim/j/johnson_shortest_paths.nim) |
| Odin | [`odin/j/johnson_shortest_paths.odin`](../../../odin/j/johnson_shortest_paths.odin) |
| Rust | [`rust/j/johnson_shortest_paths.rs`](../../../rust/j/johnson_shortest_paths.rs) |
| V | [`v/j/johnson_shortest_paths.v`](../../../v/j/johnson_shortest_paths.v) |
| Zig | [`zig/j/johnson_shortest_paths.zig`](../../../zig/j/johnson_shortest_paths.zig) |

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm johnson_shortest_paths --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/j/johnson_shortest_paths/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm johnson_shortest_paths --languages rust
```
