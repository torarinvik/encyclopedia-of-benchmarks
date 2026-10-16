# Edmonds–Karp maximum flow

Compute the maximum integral flow between one source and one sink using breadth-first search to find the shortest augmenting path. This follows the capacity-matrix form in the pinned Java source and the integer-capacity behavior shared by the pinned Go and TypeScript implementations.

## Contract

The i64-array scalar input is [vertex_count, source, sink, capacity_00, capacity_01, ..., capacity_(n-1)(n-1)], with the capacity matrix flattened in row-major order.

- The graph has 1–16 vertices, indexed from 0. The packed input length must be exactly 3 + vertex_count squared.
- Capacities are integers from 0 through 1,000,000. Self-loop capacities must be zero, and each unordered vertex pair can have capacity in at most one direction. These bounds keep residual values and total flow within signed 32-bit range and preserve the pinned adjacency-list implementation's unambiguous reverse-edge representation.
- Source and sink must be valid vertices. If they are equal, the result is 0. An otherwise valid graph with no source-to-sink path also returns 0.
- Invalid input returns -1.

The nine ports use a fixed-size residual matrix and queue storage, with no processor-specific instructions or external dependencies.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/e/edmonds_karp.c](../../../c/e/edmonds_karp.c) |
| C3 | [c3/e/edmonds_karp.c3](../../../c3/e/edmonds_karp.c3) |
| C++ | [cpp/e/edmonds_karp.cpp](../../../cpp/e/edmonds_karp.cpp) |
| Elisa | [elisa/e/edmonds_karp.elisa](../../../elisa/e/edmonds_karp.elisa) |
| Nim | [nim/e/edmonds_karp.nim](../../../nim/e/edmonds_karp.nim) |
| Odin | [odin/e/edmonds_karp.odin](../../../odin/e/edmonds_karp.odin) |
| Rust | [rust/e/edmonds_karp.rs](../../../rust/e/edmonds_karp.rs) |
| V | [v/e/edmonds_karp.v](../../../v/e/edmonds_karp.v) |
| Zig | [zig/e/edmonds_karp.zig](../../../zig/e/edmonds_karp.zig) |

## Pinned sources

- [Java capacity-matrix implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/EdmondsKarp.java)
- [Go weighted-matrix implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/edmondkarp.go), cataloged under its upstream spelling as an alias
- [TypeScript adjacency-list implementation](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/graph/edmonds_karp.ts)

The source APIs use different graph representations and numeric types. The benchmark normalizes them to a small integer-capacity matrix, excludes antiparallel input edges so the TypeScript residual-edge lookup remains well-defined, and compares the maximum flow value.

## Workload and verification

[`workload.json`](workload.json) covers residual rerouting, multiple shortest augmenting paths, disconnected sinks, equal source and sink, single-vertex graphs, and malformed capacities and bounds. The shared verifier enumerates every simple directed graph through four vertices and adds deterministic weighted graphs through eight vertices.

Verify all nine language ports with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms edmonds_karp
```
