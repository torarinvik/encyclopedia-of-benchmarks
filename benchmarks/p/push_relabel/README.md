# Push–Relabel maximum flow

Compute the maximum integral flow from a set of source vertices to a disjoint set of sink vertices. The implementations use the Push–Relabel preflow method with a deterministic scan-order active-vertex schedule. Multiple terminals are normalized with a super-source and super-sink.

## Contract

The i64-array scalar input is `[vertex_count, source_count, sources..., sink_count, sinks..., capacity_00, capacity_01, ..., capacity_(n-1)(n-1)]`; the capacity matrix is flattened in row-major order.

- Graphs have 2–14 vertices indexed from 0. Each terminal set is nonempty, contains unique in-range vertices, and the source and sink sets are disjoint. Their combined size cannot exceed the vertex count.
- Capacities are integers from 0 through 1,000,000. Self-loop capacities must be zero. Antiparallel capacities are allowed.
- The packed input length must exactly match the terminal counts and the square matrix. Invalid input returns -1. A valid network with no source-to-sink path returns 0.
- The super-source connects each source with a capacity equal to that vertex's total outgoing capacity. Every sink connects to the super-sink with a capacity equal to the combined outgoing capacity of the source set. These bounds preserve the maximum-flow value and keep arithmetic within the stated limits.

All nine ports use fixed-size arrays and portable integer operations; they use no processor-specific instructions or external dependencies.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/push_relabel.c](../../../c/p/push_relabel.c) |
| C3 | [c3/p/push_relabel.c3](../../../c3/p/push_relabel.c3) |
| C++ | [cpp/p/push_relabel.cpp](../../../cpp/p/push_relabel.cpp) |
| Elisa | [elisa/p/push_relabel.elisa](../../../elisa/p/push_relabel.elisa) |
| Nim | [nim/p/push_relabel.nim](../../../nim/p/push_relabel.nim) |
| Odin | [odin/p/push_relabel.odin](../../../odin/push_relabel.odin) |
| Rust | [rust/p/push_relabel.rs](../../../rust/p/push_relabel.rs) |
| V | [v/p/push_relabel.v](../../../v/p/push_relabel.v) |
| Zig | [zig/p/push_relabel.zig](../../../zig/p/push_relabel.zig) |

## Pinned sources

- [Java Push–Relabel implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/PushRelabel.java)
- [Python Push–Relabel implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/networking_flow/push_relabel.py)
- [Python multi-terminal source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/edmonds_karp_multiple_source_and_sink.py). Despite its filename, this source defines a `PushRelabelExecutor` and uses preflow/excess updates with relabel-to-front scheduling after adding super-terminals. Its constructor and executor currently disagree on field spelling (`vertices_count` versus `verticesCount`, and likewise for the terminal indexes); the shared contract follows the intended maximum-flow semantics.

The Java source uses FIFO active vertices; the Python networking-flow source uses a highest-label policy; the multi-terminal source uses relabel-to-front. Scheduling differs, but each is a valid Push–Relabel policy. This benchmark compares the maximum-flow value under one common bounded contract.

## Workload and verification

[`workload.json`](workload.json) includes single and multiple terminals, residual rerouting, antiparallel capacities, unreachable sinks, capacity limits, and malformed terminal sets and matrices. The shared verifier adds deterministic generated networks and malformed records.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms push_relabel
```
