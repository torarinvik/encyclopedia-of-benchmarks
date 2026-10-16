# Deep clone graph

Clone the root's reachable component of a bounded undirected graph. The implementation uses a stack and an original-node-to-clone mapping, preserving each node's value, every adjacency relation, cycles, duplicate values, and self-loops.

## Contract

- ABI: signed i64 array to signed i64 scalar.
- Input is `[n, root, value_0..value_(n-1), adjacency_mask_0..adjacency_mask_(n-1)]`, with `1 <= n <= 16`, `0 <= root < n`, signed-i32 node values, and masks in `[0,2^n)`. Masks must be symmetric. Self-loops are valid.
- Node ids are input identities, not node values; repeated values remain separate nodes. The root may reach only a component of the input; only that component is cloned and returned.
- To compare deep-clone topology through the scalar ABI, the result is the signed-i64 view of FNV-1a-64 over eight-byte little-endian words: reachable node count, root id, then each reachable node in ascending id order as `(value, adjacency mask)`. The checksum serializes the cloned graph's observable structure; object addresses are intentionally not compared.
- Invalid input returns `-1`.

The pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/deep_clone_graph.py) uses an explicit stack, maps original node identities to clones, then copies neighbor references in adjacency order. Row masks make adjacency order canonical by ascending node id while retaining all edges.

The workload covers isolated roots, paths, cycles, self-loops, duplicate values, disconnected input, a complete graph, and malformed input.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/deep_clone_graph.c`](../../../c/d/deep_clone_graph.c) |
| C3 | [`c3/d/deep_clone_graph.c3`](../../../c3/d/deep_clone_graph.c3) |
| C++ | [`cpp/d/deep_clone_graph.cpp`](../../../cpp/d/deep_clone_graph.cpp) |
| Elisa | [`elisa/d/deep_clone_graph.elisa`](../../../elisa/d/deep_clone_graph.elisa) |
| Nim | [`nim/d/deep_clone_graph.nim`](../../../nim/d/deep_clone_graph.nim) |
| Odin | [`odin/d/deep_clone_graph.odin`](../../../odin/d/deep_clone_graph.odin) |
| Rust | [`rust/d/deep_clone_graph.rs`](../../../rust/d/deep_clone_graph.rs) |
| V | [`v/d/deep_clone_graph.v`](../../../v/d/deep_clone_graph.v) |
| Zig | [`zig/d/deep_clone_graph.zig`](../../../zig/d/deep_clone_graph.zig) |
