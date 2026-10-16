# Gomory–Hu tree

Build a weighted tree that represents every pairwise minimum cut of a bounded undirected graph. The pinned Java source applies the Gomory–Hu parent update using `n-1` Edmonds–Karp flows. This differs from the existing Edmonds–Karp benchmark, which returns one source/sink flow value.

## Contract

Input is `[vertex_count, capacity_matrix_row_major...]`. There are 1–8 vertices; capacities are symmetric integers from 0 to 1,000 with a zero diagonal. Invalid input returns `-1`.

The scalar result is a signed FNV-1a hash of the row-major pairwise minimum-cut matrix represented by the constructed tree. Hashing all-pairs cut values makes the contract independent of which valid tree representation a construction chooses. The independent oracle enumerates cuts directly rather than constructing a Gomory–Hu tree.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gomory_hu_tree.c`](../../../c/g/gomory_hu_tree.c) |
| C3 | [`c3/g/gomory_hu_tree.c3`](../../../c3/g/gomory_hu_tree.c3) |
| C++ | [`cpp/g/gomory_hu_tree.cpp`](../../../cpp/g/gomory_hu_tree.cpp) |
| Elisa | [`elisa/g/gomory_hu_tree.elisa`](../../../elisa/g/gomory_hu_tree.elisa) |
| Nim | [`nim/g/gomory_hu_tree.nim`](../../../nim/g/gomory_hu_tree.nim) |
| Odin | [`odin/g/gomory_hu_tree.odin`](../../../odin/g/gomory_hu_tree.odin) |
| Rust | [`rust/g/gomory_hu_tree.rs`](../../../rust/g/gomory_hu_tree.rs) |
| V | [`v/g/gomory_hu_tree.v`](../../../v/g/gomory_hu_tree.v) |
| Zig | [`zig/g/gomory_hu_tree.zig`](../../../zig/g/gomory_hu_tree.zig) |

## Pinned source

[TheAlgorithms/Java `GomoryHuTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/GomoryHuTree.java)
