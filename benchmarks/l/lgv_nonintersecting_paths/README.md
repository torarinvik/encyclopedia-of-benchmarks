# Lindström–Gessel–Viennot nonintersecting paths

Given a small blocked rectangular grid, count families of pairwise
vertex-disjoint paths that start at ordered cells on the left boundary and end
at ordered cells on the right boundary. A path moves only right or down. The
input is `[height,width,path_count,blocked_mask,source_rows...,sink_rows...]`;
the source and sink row lists must each be strictly increasing, and each
source row must not exceed its paired sink row. A blocked terminal, malformed
input, or out-of-domain value returns `-1`.

The implementation computes every single-source/single-sink path count by
grid dynamic programming, then evaluates the small path-count matrix
determinant by its permutation expansion. Because the ordered boundary
terminals in this planar monotone grid admit no vertex-disjoint crossing
pairing, the LGV determinant equals the requested nonnegative count for the
order-preserving pairing. The independent reference instead enumerates
monotone paths and counts compatible disjoint families directly.

The benchmark uses at most a 5-by-5 grid and three paths. Its algorithmic
work is `O(K*H*W + K^3)` time and `O(H*W + K^2)` auxiliary space. The
independent enumerator is suitable for the bounded fixtures and is not part
of the timed implementation.

The method follows [OI Wiki's LGV lemma entry](https://oi-wiki.org/graph/lgv/).
Only the algorithm description was consulted; all code, contract text, and
fixtures are independently authored.

| Language | Port |
|---|---|
| C | [c/l/lgv_nonintersecting_paths.c](../../../c/l/lgv_nonintersecting_paths.c) |
| C3 | [c3/l/lgv_nonintersecting_paths.c3](../../../c3/l/lgv_nonintersecting_paths.c3) |
| C++ | [cpp/l/lgv_nonintersecting_paths.cpp](../../../cpp/l/lgv_nonintersecting_paths.cpp) |
| Elisa | [elisa/l/lgv_nonintersecting_paths.elisa](../../../elisa/l/lgv_nonintersecting_paths.elisa) |
| Mojo | [mojo/l/lgv_nonintersecting_paths.mojo](../../../mojo/l/lgv_nonintersecting_paths.mojo) |
| Nim | [nim/l/lgv_nonintersecting_paths.nim](../../../nim/l/lgv_nonintersecting_paths.nim) |
| Odin | [odin/l/lgv_nonintersecting_paths.odin](../../../odin/l/lgv_nonintersecting_paths.odin) |
| Rust | [rust/l/lgv_nonintersecting_paths.rs](../../../rust/l/lgv_nonintersecting_paths.rs) |
| V | [v/l/lgv_nonintersecting_paths.v](../../../v/l/lgv_nonintersecting_paths.v) |
| Zig | [zig/l/lgv_nonintersecting_paths.zig](../../../zig/l/lgv_nonintersecting_paths.zig) |
