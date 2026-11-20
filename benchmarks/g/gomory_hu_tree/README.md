# Gomory–Hu tree

Build a weighted tree that represents every pairwise minimum cut of a bounded undirected graph. The Gusfield parent-update construction performs `n-1` minimum-cut computations on the original graph; these ports use Edmonds–Karp with neighbors scanned in ascending vertex order. For any two distinct vertices, their minimum-cut value is the minimum edge weight on their tree path.

This differs from the existing [`edmonds_karp`](../../e/edmonds_karp/README.md) benchmark, which returns one source/sink flow value, and [`edge_connectivity_all_pairs_maxflow`](../../e/edge_connectivity_all_pairs_maxflow/README.md), which returns only the global minimum pairwise connectivity. [`stoer_wagner`](../../s/stoer_wagner/README.md) also returns a single global cut value.

## Contract

Input is `[vertex_count, capacity_matrix_row_major...]` with exactly `1 + vertex_count^2` values (maximum 65). There are 1–8 vertices; capacities are symmetric integers from 0 to 1,000 with a zero diagonal. A mirrored pair of matrix entries describes one undirected edge with that capacity, not two contributions to a cut. Disconnected graphs and zero-capacity edges are valid. Invalid input returns `-1`.

Let `lambda[i,j]` be the minimum cut value between distinct vertices `i` and `j`, and define `lambda[i,i] = 0`. If there is no positive-capacity path between a pair, `lambda[i,j] = 0`. The scalar result is the signed interpretation of a 64-bit FNV-1a hash of the row-major `vertex_count * vertex_count` matrix of these values. For each matrix value, hash its eight little-endian bytes in order, starting from offset basis `14695981039346656037` and multiplying by prime `1099511628211` after each byte. Multiplication wraps modulo `2^64`; reinterpret the final 64-bit pattern as signed `i64` for the result. This value-based signature is independent of which valid tree representation a construction chooses. The independent oracle enumerates cuts directly rather than constructing a Gomory–Hu tree. For an undirected cut, the direct oracle counts each crossing capacity once (equivalently, it may sum both matrix orientations and divide by two).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gomory_hu_tree.c`](../../../c/g/gomory_hu_tree.c) |
| C3 | [`c3/g/gomory_hu_tree.c3`](../../../c3/g/gomory_hu_tree.c3) |
| C++ | [`cpp/g/gomory_hu_tree.cpp`](../../../cpp/g/gomory_hu_tree.cpp) |
| Elisa | [`elisa/g/gomory_hu_tree.elisa`](../../../elisa/g/gomory_hu_tree.elisa) |
| Mojo | [`mojo/g/gomory_hu_tree.mojo`](../../../mojo/g/gomory_hu_tree.mojo) |
| Nim | [`nim/g/gomory_hu_tree.nim`](../../../nim/g/gomory_hu_tree.nim) |
| Odin | [`odin/g/gomory_hu_tree.odin`](../../../odin/g/gomory_hu_tree.odin) |
| Rust | [`rust/g/gomory_hu_tree.rs`](../../../rust/g/gomory_hu_tree.rs) |
| V | [`v/g/gomory_hu_tree.v`](../../../v/g/gomory_hu_tree.v) |
| Zig | [`zig/g/gomory_hu_tree.zig`](../../../zig/g/gomory_hu_tree.zig) |

## Sources and rights

[Gomory and Hu's 1961 paper](https://doi.org/10.1137/0109047) establishes the cut-equivalent tree for undirected capacitated graphs and the `n-1` flow construction. The parent-update method used here is Gusfield's non-contraction variant, described in [“Very Simple Methods for All Pairs Network Flow Analysis”](https://doi.org/10.1137/0219009). The [pinned TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/GomoryHuTree.java) was also consulted as an implementation reference. See [`RIGHTS.md`](RIGHTS.md) for license and clean-room provenance.

ABI: `i64_array_scalar`, symbol `gomory_hu_tree`.
