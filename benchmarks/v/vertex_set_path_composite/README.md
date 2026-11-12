# Vertex set path composite

Each tree vertex stores an affine function `f(x)=a*x+b` modulo 998244353.
Updates replace one vertex's function. A path query applies the functions in
the directed order from `u` to `v`: the function at `u` runs first and the
function at `v` runs last. The implementation uses heavy-light decomposition
and a segment tree that stores both forward and reverse compositions for each
range.

For adjacent path ranges `L` then `R`, their combined map is `R ∘ L`, or
`(aR*aL, aR*bL+bR) mod 998244353`. The two segment-tree directions preserve
this noncommutative order when a path moves upward or downward through the
decomposition.

## Contract

The bounded ABI encodes
`[N,Q,(a,b)*N,(u,v)*(N-1),(operation,p,c,d)*Q]`, with `1 <= N,Q <= 64`.
Operation `0` replaces vertex `p`'s map with `c*x+d`; operation `1` queries
the map composition along the path from `p` to `c`, applied to `d` (the four
fields are interpreted as `1,u,v,x`). Initial and update multipliers are in
`1..998244352`; offsets and query inputs are residues in `0..998244352`.
Edges must form a tree. Successful calls write one signed 64-bit
little-endian answer per query. Invalid input returns `-1`; a null or
undersized output buffer returns `-2` without writing. The maximum input is
512 integers and the maximum output/workspace is 512 bytes. Here
`workspace.bytes=512` is output-buffer capacity; HLD and segment-tree arrays
are separate.

The official task permits `N,Q <= 200000`; this bounded profile retains the
HLD and bidirectional segment-tree query structure at smaller limits.

## Distinctness

[`point_set_range_composite`](../../p/point_set_range_composite/README.md)
composes functions over contiguous array ranges. This package composes the
vertex functions in path order on a tree. The local HLD path-sum and path-max
packages use commutative aggregates and do not preserve affine composition
direction.

Official contract: [Library Checker — Vertex Set Path Composite](https://github.com/yosupo06/library-checker-problems/blob/master/tree/vertex_set_path_composite/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/tree/vertex_set_path_composite/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers opposite path directions, same-vertex
queries, point updates, branching paths, malformed tree input, invalid affine
coefficients, and insufficient capacity. The independent
[`benchmarks/vertex_set_path_composite_oracle.py`](../../vertex_set_path_composite_oracle.py)
finds each path directly and applies the maps one vertex at a time.

## Implementations

| Language | Port |
|---|---|
| C | [`c/v/vertex_set_path_composite.c`](../../../c/v/vertex_set_path_composite.c) |
| C3 | [`c3/v/vertex_set_path_composite.c3`](../../../c3/v/vertex_set_path_composite.c3) |
| C++ | [`cpp/v/vertex_set_path_composite.cpp`](../../../cpp/v/vertex_set_path_composite.cpp) |
| Elisa | [`elisa/v/vertex_set_path_composite.elisa`](../../../elisa/v/vertex_set_path_composite.elisa) |
| Nim | [`nim/v/vertex_set_path_composite.nim`](../../../nim/v/vertex_set_path_composite.nim) |
| Odin | [`odin/v/vertex_set_path_composite.odin`](../../../odin/v/vertex_set_path_composite.odin) |
| Rust | [`rust/v/vertex_set_path_composite.rs`](../../../rust/v/vertex_set_path_composite.rs) |
| V | [`v/v/vertex_set_path_composite.v`](../../../v/v/vertex_set_path_composite.v) |
| Zig | [`zig/v/vertex_set_path_composite.zig`](../../../zig/v/vertex_set_path_composite.zig) |
| Mojo | [`mojo/v/vertex_set_path_composite.mojo`](../../../mojo/v/vertex_set_path_composite.mojo) |
