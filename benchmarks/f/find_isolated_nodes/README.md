# Find isolated nodes

This benchmark returns vertices whose adjacency lists are empty. It follows TheAlgorithms/Python's `find_isolated_nodes` predicate: on an undirected graph, these are the isolated vertices; on a directed graph, a vertex with incoming edges but no outgoing edges also qualifies. The result is normalized to ascending vertex ID order.

## Contract

- Input is a signed 64-bit array `[vertex_count, source_0, destination_0, ...]` describing directed adjacency lists. Every vertex from `0` through `vertex_count - 1` is present, including vertices with no outgoing edges.
- There are 0–64 vertices and 0–32 directed edges. The input contains exactly one vertex count followed by zero or more endpoint pairs. Endpoints must be in range. Duplicate edges are coalesced; self-loops make their vertex non-isolated.
- The function returns the number of vertices with no outgoing neighbors and writes their IDs as one byte each, in ascending order. The empty graph returns zero with no output.
- Malformed input or insufficient output capacity returns `-2` without writing output.
- Implementations use fixed-size adjacency bitsets and portable integer operations.

## Source mapping

The pinned Python source scans each dictionary key and selects it when its neighbor list is empty. The local contract uses dense zero-based IDs and a packed edge list so it can be shared across all nine languages. Symmetric edge pairs model undirected graphs; one-way edges retain the source function's empty-adjacency behavior.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm find_isolated_nodes --language elisa
python3 benchmarks/run_i64_array_bytes_output.py --algorithm find_isolated_nodes
python3 benchmarks/verify_find_isolated_nodes.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/find_isolated_nodes.c`](../../../c/f/find_isolated_nodes.c) |
| C3 | [`c3/f/find_isolated_nodes.c3`](../../../c3/f/find_isolated_nodes.c3) |
| C++ | [`cpp/f/find_isolated_nodes.cpp`](../../../cpp/f/find_isolated_nodes.cpp) |
| Elisa | [`elisa/f/find_isolated_nodes.elisa`](../../../elisa/f/find_isolated_nodes.elisa) |
| Nim | [`nim/f/find_isolated_nodes.nim`](../../../nim/f/find_isolated_nodes.nim) |
| Odin | [`odin/f/find_isolated_nodes.odin`](../../../odin/f/find_isolated_nodes.odin) |
| Rust | [`rust/f/find_isolated_nodes.rs`](../../../rust/f/find_isolated_nodes.rs) |
| V | [`v/f/find_isolated_nodes.v`](../../../v/f/find_isolated_nodes.v) |
| Zig | [`zig/f/find_isolated_nodes.zig`](../../../zig/f/find_isolated_nodes.zig) |

## Pinned source

- TheAlgorithms/Python [`basic_graphs.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/basic_graphs.py)
