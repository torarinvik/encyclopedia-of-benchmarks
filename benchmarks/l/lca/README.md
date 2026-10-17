# Lowest Common Ancestor

Compute the lowest common ancestor of two vertices in the pinned Java tree, rooted at vertex 0. The source performs a DFS to assign parent and depth values, then raises the deeper query vertex and climbs both parent links until they meet.

## Contract

- ABI: i64_array_scalar.
- Input is [node_count, (edge_u, edge_v) repeated node_count-1 times, query_u, query_v], with 1–64 vertices and exact length 2 * node_count + 1.
- The graph must be one undirected tree: all IDs are in 0..node_count-1, there are no self edges, duplicate edges, or cycles, and every vertex is connected to vertex 0.
- Return the LCA vertex ID as a signed 64-bit integer. Invalid or null input returns -1. With one vertex and query (0, 0), the result is 0.

## Workload

[workload.json](workload.json) covers the pinned sample tree, root/ancestor/sibling cases, same-node queries, maximum tree size, and invalid tree/framing inputs. See the [oracle](../../lca_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/lca.c](../../../c/l/lca.c) |
| C3 | [c3/l/lca.c3](../../../c3/l/lca.c3) |
| C++ | [cpp/l/lca.cpp](../../../cpp/l/lca.cpp) |
| Elisa | [elisa/l/lca.elisa](../../../elisa/l/lca.elisa) |
| Nim | [nim/l/lca.nim](../../../nim/l/lca.nim) |
| Odin | [odin/l/lca.odin](../../../odin/l/lca.odin) |
| Rust | [rust/l/lca.rs](../../../rust/l/lca.rs) |
| V | [v/l/lca.v](../../../v/l/lca.v) |
| Zig | [zig/l/lca.zig](../../../zig/l/lca.zig) |

## Pinned source

[TheAlgorithms/Java LCA](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/LCA.java) at e43ec3897e48f23843972d02cd05a5bb1b6864a2.

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lca --language rust
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/lca/rust/build.json
    python3 benchmarks/verify_i64_array_scalar.py --algorithm lca
