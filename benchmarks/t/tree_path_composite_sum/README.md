# Tree path composite sum

For each vertex `r` as a root, return the sum of `P(r,v)` over every vertex `v` in a tree, modulo 998244353. Every vertex has a value `A_v`; every undirected edge carries the affine map `f(x)=b*x+c`, applied in the same direction-independent way when the path is traversed either way. On the path from `r` to `v`, the first edge map is outermost, so `P(r,v)=f_0(f_1(...f_k(A_v)...))`; the empty path returns `A_r`.

The ports use rerooting dynamic programming. A directed component message stores the sum of path values rooted at its boundary vertex and the number of vertices represented. A postorder pass computes child-side messages. A preorder pass combines all incoming messages, removes one child contribution, and applies that edge's affine map to send the complementary message in the opposite direction. The message recurrence takes `O(N)` work with adjacency lists; this bounded profile deliberately uses dense edge-lookup tables and scans the bounded vertex range, so the written ports take `O(N^2)` time and reserve `O(N^2)` storage. The local size cap does not claim official large-scale performance.

The bounded workload uses `1 <= N <= 32`, values and affine coefficients modulo 998244353, and an `N-1` edge list validated as a simple tree. Input is `[N,A_0,...,A_(N-1),u_0,v_0,b_0,c_0,...]`. Output is one little-endian signed 64-bit residue for each root in vertex-index order. Invalid input returns `-1`; null or undersized output returns `-2` without writes. This local profile measures the rerooting algorithm and does not claim the official `N <= 200,000` scale.

The primary oracle reconstructs each target path directly. The separate verifier composes affine maps while traversing from each root. Fixtures include direction-sensitive paths, asymmetric edge maps, identity maps, malformed trees, and output-capacity behavior.

The official task is [Library Checker — Tree Path Composite Sum](https://github.com/yosupo06/library-checker-problems/blob/master/tree/tree_path_composite_sum/task.md); limits are [here](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/tree_path_composite_sum/info.toml). These ports are clean-room implementations from the task definition. The upstream problem repository declares Apache-2.0; no submission source or test material is reused.

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/tree_path_composite_sum.c`](../../../c/t/tree_path_composite_sum.c) |
| C3 | [`c3/t/tree_path_composite_sum.c3`](../../../c3/t/tree_path_composite_sum.c3) |
| C++ | [`cpp/t/tree_path_composite_sum.cpp`](../../../cpp/t/tree_path_composite_sum.cpp) |
| Elisa | [`elisa/t/tree_path_composite_sum.elisa`](../../../elisa/t/tree_path_composite_sum.elisa) |
| Mojo | [`mojo/t/tree_path_composite_sum.mojo`](../../../mojo/t/tree_path_composite_sum.mojo) |
| Nim | [`nim/t/tree_path_composite_sum.nim`](../../../nim/t/tree_path_composite_sum.nim) |
| Odin | [`odin/t/tree_path_composite_sum.odin`](../../../odin/t/tree_path_composite_sum.odin) |
| Rust | [`rust/t/tree_path_composite_sum.rs`](../../../rust/t/tree_path_composite_sum.rs) |
| V | [`v/t/tree_path_composite_sum.v`](../../../v/t/tree_path_composite_sum.v) |
| Zig | [`zig/t/tree_path_composite_sum.zig`](../../../zig/t/tree_path_composite_sum.zig) |
