# Dynamic Point Set Rectangle Affine Rectangle Sum

This benchmark maintains a multiset of weighted points in a two-dimensional plane. It supports appending a point, assigning a point’s weight, summing weights in a half-open rectangle, and applying one modular affine transformation to every currently existing point in a rectangle.

The operation order follows the official task: type `0` appends `(x,y,w)` as the next point; type `1` sets point `k` to weight `w`; type `2` sums weights in `[left,right) × [down,up)` modulo 998244353; type `3` transforms each covered weight as `w ← a*w+b` modulo 998244353. Duplicate coordinates remain separate points.

The bounded profile uses `1 <= N,Q <= 32`, coordinates from 0 through 1,000,000,000, and weights and affine coefficients in `[0,998244353)`. It parses the whole trace first and builds a balanced k-d tree over all initial and future append coordinates. Future points start inactive: rectangle updates and sums count only points already appended, and activating a point assigns its insertion weight without applying earlier transforms. This preserves the online operation semantics while allowing a fixed node pool.

Each tree node stores its point bounding box, active point count, modular weight sum, and lazy affine tag. Fully covered nodes apply an affine map to the aggregate using the active count. Point assignments descend to the precomputed leaf for that point ID. The tree is balanced by alternating coordinate axes. Building uses bounded insertion sorts for the local profile, with worst-case `O(P²)` setup for `P <= 64`; point assignment takes `O(log P)`. A rectangle operation takes `O(P)` in the worst case. Tree storage is `O(P)`; the byte-output workspace of 256 bytes is reserved for at most 32 query results.

The package oracle and verifier use direct point-list scans and updates, independent of the k-d tree. All ten ports are clean-room implementations based on the public contract.

## Provenance and distinctness

- [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/dynamic_point_set_rectangle_affine_rectangle_sum/task.md)
- [Official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/dynamic_point_set_rectangle_affine_rectangle_sum/info.toml)
- [Official online solution](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/dynamic_point_set_rectangle_affine_rectangle_sum/sol/online.cpp)

This combines dynamic sparse points, point assignment, rectangle sums, and rectangle affine updates. `segment_tree2_d` assigns cells in a small dense matrix and queries rectangle sums; `point_add_rectangle_sum` appends sparse points and queries rectangle sums; the existing affine range packages operate on one-dimensional sequences. None has this combined two-dimensional operation set.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/dynamic_point_set_rectangle_affine_rectangle_sum.c`](../../../c/d/dynamic_point_set_rectangle_affine_rectangle_sum.c) |
| C3 | [`c3/d/dynamic_point_set_rectangle_affine_rectangle_sum.c3`](../../../c3/d/dynamic_point_set_rectangle_affine_rectangle_sum.c3) |
| C++ | [`cpp/d/dynamic_point_set_rectangle_affine_rectangle_sum.cpp`](../../../cpp/d/dynamic_point_set_rectangle_affine_rectangle_sum.cpp) |
| Elisa | [`elisa/d/dynamic_point_set_rectangle_affine_rectangle_sum.elisa`](../../../elisa/d/dynamic_point_set_rectangle_affine_rectangle_sum.elisa) |
| Mojo | [`mojo/d/dynamic_point_set_rectangle_affine_rectangle_sum.mojo`](../../../mojo/d/dynamic_point_set_rectangle_affine_rectangle_sum.mojo) |
| Nim | [`nim/d/dynamic_point_set_rectangle_affine_rectangle_sum.nim`](../../../nim/d/dynamic_point_set_rectangle_affine_rectangle_sum.nim) |
| Odin | [`odin/d/dynamic_point_set_rectangle_affine_rectangle_sum.odin`](../../../odin/d/dynamic_point_set_rectangle_affine_rectangle_sum.odin) |
| Rust | [`rust/d/dynamic_point_set_rectangle_affine_rectangle_sum.rs`](../../../rust/d/dynamic_point_set_rectangle_affine_rectangle_sum.rs) |
| V | [`v/d/dynamic_point_set_rectangle_affine_rectangle_sum.v`](../../../v/d/dynamic_point_set_rectangle_affine_rectangle_sum.v) |
| Zig | [`zig/d/dynamic_point_set_rectangle_affine_rectangle_sum.zig`](../../../zig/d/dynamic_point_set_rectangle_affine_rectangle_sum.zig) |
