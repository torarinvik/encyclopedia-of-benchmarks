# Well-separated pair decomposition (WSPD)

This bounded profile constructs a WSPD for up to eight distinct points in two dimensions. It follows the pinned reference's split-tree, bounding-sphere separation, and recursive pair-decomposition approach. To make the small benchmark deterministic across languages, it uses a median split on the widest coordinate axis, breaking coordinate ties by the other coordinate and then original input index. The pinned C++ implementation uses a partial fair-split tree with linked coordinate orderings; this profile fixes the tree shape while preserving the source's separation inequality and pair traversal.

## Contract

- ABI: `i64_array_bytes_output`; input is `[point_count, separation_factor, x0, y0, ...]`.
- `point_count` is 1..8, `separation_factor` is an integer in 1..8, and every integer coordinate is in `[-1000,1000]`. Coordinates must be unique. Invalid inputs return `-1`.
- The tree uses the axis with the greater bounding-box span (x wins ties). It sorts by the selected coordinate, then the other coordinate, then input index, and divides at `floor(count/2)`. Each node stores the bounding-box center and the radius of its enclosing sphere.
- For nodes A and B, let `R=max(radius(A),radius(B))` and `d` be the Euclidean distance between centers. The source's strict acceptance test is `d - 2*R > separation_factor*R`. If it fails, split the node with larger radius; ties split B. A tree node visits its left subtree, then its right subtree, then decomposes the pair of its children. The resulting pairs cover each unordered pair of distinct points exactly once.
- Output is little-endian signed 64-bit words: `[pair_count, left_mask_0, right_mask_0, ...]`. A mask's bit `i` denotes original input point `i`. Pair order is the deterministic depth-first traversal order above. Return the output byte count. A null/short output buffer returns `-2` without writes.
- With at most eight points there are at most 28 emitted pairs, so output is bounded by 456 bytes. Workspace uses at most 15 tree nodes and a 456-byte staging buffer.

The pinned reference is Domagoj Matijević's [`wspd_pip` implementation](https://github.com/dmatijev/wspd_pip/tree/6bbe228bb13993d8ee972671acde8e76c9330eda), especially `src/wsp.cpp` and `src/findwsp.cpp`, at commit `6bbe228bb13993d8ee972671acde8e76c9330eda`. The original project is MIT-licensed; its complete notice is bundled in [`LICENSE.md`](LICENSE.md). This profile uses the documented source-level separation rule and decomposition traversal with a fixed small median split tree.

## Workload and oracle

[`workload.json`](workload.json) covers a singleton, two-point pair, a three-point recursive split, a separated cluster pair, duplicate coordinates, and malformed input. The independent [oracle](../../wspd_oracle.py) constructs the bounded tree in Python and serializes index masks.

## Implementations

| Language | Port |
|---|---|
| C | [`c/w/wspd.c`](../../../c/w/wspd.c) |
| C3 | [`c3/w/wspd.c3`](../../../c3/w/wspd.c3) |
| C++ | [`cpp/w/wspd.cpp`](../../../cpp/w/wspd.cpp) |
| Elisa | [`elisa/w/wspd.elisa`](../../../elisa/w/wspd.elisa) |
| Nim | [`nim/w/wspd.nim`](../../../nim/w/wspd.nim) |
| Odin | [`odin/w/wspd.odin`](../../../odin/w/wspd.odin) |
| Rust | [`rust/w/wspd.rs`](../../../rust/w/wspd.rs) |
| V | [`v/w/wspd.v`](../../../v/w/wspd.v) |
| Zig | [`zig/w/wspd.zig`](../../../zig/w/wspd.zig) |
