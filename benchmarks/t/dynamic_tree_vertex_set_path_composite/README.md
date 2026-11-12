# Dynamic tree vertex set path composite

This package implements Library Checker `dynamic_tree_vertex_set_path_composite`.
Vertices carry affine maps `f_i(t)=a_i*t+b_i` over `F_998244353`. The tree can
replace an edge, update a vertex map, and query the ordered map composition on
an oriented path. A path `p_1=u,...,p_k=v` returns
`f_pk(...f_p2(f_p1(x))...)` modulo the field modulus.

## Bounded ABI

The exported C ABI is
`int64_t dynamic_tree_vertex_set_path_composite(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`.
Input starts `[N,Q]`, then `N` pairs `(a_i,b_i)`, `N-1` initial edge pairs,
and `Q` variable-width records. Type 0 is `[0,u,v,w,x]` (cut `(u,v)`, link
`(w,x)`); type 1 is `[1,p,c,d]` (set map `f_p(t)=c*t+d`); type 2 is
`[2,u,v,x]` (query the map composition from `u` to `v`). Each edge update
must preserve a connected tree.

The local profile uses `1<=N<=8`, `1<=Q<=12`, initial and updated
multipliers in `1..998244352`, and addends and query arguments in
`0..998244352`. Malformed input returns `-1`. A valid input with null output
or capacity below eight bytes per type-2 query returns `-2`, without writes.
Success writes one little-endian signed 64-bit residue per type-2 query in
query order; updates produce no result. The maximum input is 92 words and the
maximum output is 96 bytes. An update-only trace returns zero bytes and still
requires a nonnull output pointer.

The ports use a Link-Cut Tree with an orientation-aware affine monoid. For a
splay path sequence, each node maintains both forward and reverse affine
compositions. Reversal swaps both child links and these summaries; path
exposure then yields the requested `u`-to-`v` composition. Each operation is
`O(log N)` amortized and the data structure uses `O(N)` storage.

This is distinct from [static `vertex_set_path_composite`](../../../benchmarks/v/vertex_set_path_composite/README.md),
which uses HLD and a segment tree on fixed topology, and from
[`link_cut_tree`](../link_cut_tree/README.md), which maintains additive path
sums rather than noncommutative affine compositions.

The primary oracle uses the Link-Cut Tree summary; the independent oracle
reconstructs each requested path directly through the current adjacency graph
and applies vertex maps in path order.

## Source and rights

Official statement: [Library Checker — Dynamic Tree Vertex Set Path Composite](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_set_path_composite/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/dynamic_tree_vertex_set_path_composite/info.toml).
The official constraints allow `N,Q<=200000`; the local profile intentionally
caps them at 8 and 12. The upstream task repository declares Apache-2.0; see
[RIGHTS.md](RIGHTS.md). The ports, bounded workload, oracles, and prose are
clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). The workload is intended for the
shared byte-output runner and verifier.

| Language | Source |
|---|---|
| C | [c/t/dynamic_tree_vertex_set_path_composite.c](../../../c/t/dynamic_tree_vertex_set_path_composite.c) |
| C3 | [c3/t/dynamic_tree_vertex_set_path_composite.c3](../../../c3/t/dynamic_tree_vertex_set_path_composite.c3) |
| C++ | [cpp/t/dynamic_tree_vertex_set_path_composite.cpp](../../../cpp/t/dynamic_tree_vertex_set_path_composite.cpp) |
| Elisa | [elisa/t/dynamic_tree_vertex_set_path_composite.elisa](../../../elisa/t/dynamic_tree_vertex_set_path_composite.elisa) |
| Mojo | [mojo/t/dynamic_tree_vertex_set_path_composite.mojo](../../../mojo/t/dynamic_tree_vertex_set_path_composite.mojo) |
| Nim | [nim/t/dynamic_tree_vertex_set_path_composite.nim](../../../nim/t/dynamic_tree_vertex_set_path_composite.nim) |
| Odin | [odin/t/dynamic_tree_vertex_set_path_composite.odin](../../../odin/t/dynamic_tree_vertex_set_path_composite.odin) |
| Rust | [rust/t/dynamic_tree_vertex_set_path_composite.rs](../../../rust/t/dynamic_tree_vertex_set_path_composite.rs) |
| V | [v/t/dynamic_tree_vertex_set_path_composite.v](../../../v/t/dynamic_tree_vertex_set_path_composite.v) |
| Zig | [zig/t/dynamic_tree_vertex_set_path_composite.zig](../../../zig/t/dynamic_tree_vertex_set_path_composite.zig) |
