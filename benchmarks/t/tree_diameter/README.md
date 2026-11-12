# Weighted tree diameter path

Given a positively weighted undirected tree, find a farthest pair of vertices
and return the path between them. The implementation performs two tree
traversals: from vertex 0 to a farthest endpoint, then from that endpoint to
the opposite endpoint while recording parents. Farthest-distance ties choose
the smallest vertex ID, which makes the emitted path reproducible across
ports.

## Contract

The official input contains `N`, followed by `N-1` weighted edges `(u,v,w)`.
The official output is the path weight, its number of vertices, and the path
vertices in traversal order. Official weights satisfy `1 <= w <= 10^9`.

The bounded ABI encodes `[N,(u,v,w)...]`, with `1 <= N <= 64`. Inputs must be
connected trees with distinct endpoints and valid positive weights; malformed
trees return `-1`. The maximum path weight is `63*10^9`, within signed 64-bit.
Successful calls write `[distance,path_length,vertices...]` as signed 64-bit
little-endian values. A null or undersized output buffer returns `-2` without
writing. The maximum output is `(2+N)*8 = 528` bytes, so `workspace.bytes=528`
represents output-buffer capacity; graph and traversal arrays are separate.

## Distinctness

The local [`diameter_of_binary_tree`](../../d/diameter_of_binary_tree/README.md)
operates on binary-tree child links and returns an unweighted diameter. This
benchmark accepts arbitrary weighted trees and reconstructs an actual
maximum-weight path, so it measures a distinct tree traversal and path
reconstruction workload.

Official contract: [Library Checker — Tree Diameter](https://github.com/yosupo06/library-checker-problems/blob/master/tree/tree_diameter/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/tree/tree_diameter/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers a singleton, a weighted chain, a
weighted star, tied diameters, malformed cyclic input, and insufficient
output capacity. The independent
[`benchmarks/tree_diameter_oracle.py`](../../tree_diameter_oracle.py) validates
the tree, computes distances by direct traversal, and reconstructs the
deterministically selected farthest path.

## Implementations

| Language | Port |
|---|---|
| C | [`c/t/tree_diameter.c`](../../../c/t/tree_diameter.c) |
| C3 | [`c3/t/tree_diameter.c3`](../../../c3/t/tree_diameter.c3) |
| C++ | [`cpp/t/tree_diameter.cpp`](../../../cpp/t/tree_diameter.cpp) |
| Elisa | [`elisa/t/tree_diameter.elisa`](../../../elisa/t/tree_diameter.elisa) |
| Nim | [`nim/t/tree_diameter.nim`](../../../nim/t/tree_diameter.nim) |
| Odin | [`odin/t/tree_diameter.odin`](../../../odin/t/tree_diameter.odin) |
| Rust | [`rust/t/tree_diameter.rs`](../../../rust/t/tree_diameter.rs) |
| V | [`v/t/tree_diameter.v`](../../../v/t/tree_diameter.v) |
| Zig | [`zig/t/tree_diameter.zig`](../../../zig/t/tree_diameter.zig) |
| Mojo | [`mojo/t/tree_diameter.mojo`](../../../mojo/t/tree_diameter.mojo) |
