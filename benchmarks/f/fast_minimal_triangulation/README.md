# Fast minimal triangulation

This package implements the recursive FMT kernel: select a connected vertex set
`K`, form `A=N[K]`, find components `C_i` of `G-A`, make each `N(C_i)` a clique,
and recurse on the saturated induced graphs over `A` and each `N[C_i]`. The
bounded profile refines the paper's choice to `K={lowest-ID non-universal
vertex}`. This is a connected singleton and guarantees strict size reduction
in every recursive subproblem. Complete subgraphs are returned unchanged.

The input ABI is `i64_array_bytes_output`, with `[n,m,(u,v)*m]`, `1<=n<=8`,
`0<=m<=28`, simple undirected edges `u<v` in strict lexicographic order. At
most 58 words form a valid frame; 59 words are accepted by the parser as the
malformed-frame ceiling for one trailing value. The result is little-endian
i64 bytes `[f,(u,v)*f]`, where fill edges are sorted lexicographically. The
maximum result allocation is 456 bytes; the documented native workspace cap
is 4,096 bytes. Invalid input returns `-1`; null or short output returns `-2`
without writing to the output buffer.

Chapter 142, Villanger's “Fast Minimal Triangulation,” points to Heggernes,
Telle, and Villanger's operational recursive method in [the SIAM paper, DOI
10.1137/S0895480104445010](https://doi.org/10.1137/S0895480104445010). This
profile measures the recursive separator-saturation method with a deterministic
singleton pivot and bounded graph representation. It does not implement the
paper's balanced pivot-selection machinery or matrix-multiplication
acceleration, and it does **not** claim the published
`O(n^α log n)` running-time bound. A subproblem uses `O(n²)` bounded component
and saturation work. With subproblem size `s`, at most `s` strictly smaller
children are created, giving the loose call-count recurrence
`T(1)=1`, `T(s)<=1+s*T(s-1)`; thus `T(8)<=69,281` and the profile's
conservative time bound is `O(n² T(n))`. Recursion depth is at most eight.
Fixed graph/component arrays and active recursive frames fit under the
4,096-byte workspace cap; serialized output uses the caller's buffer. Local
benchmarks for chordal recognition,
minimum-fill elimination heuristics, and polygon triangulation do not compute
the same inclusion-minimal chordal completion by this recurrence.

`primary_oracle.py` uses fixed-width adjacency bitsets and returns fill edges
as a bit mask. `independent_oracle.py` uses immutable edge sets and explicit
set construction. The workload includes chordal, complete, disconnected,
cycle, and malformed/capacity cases. Static package helpers are provided but
have not been executed. Source is independently written from published
algorithmic ideas; see [RIGHTS.md](RIGHTS.md).

Ports: [C](../../../c/f/fast_minimal_triangulation.c),
[C3](../../../c3/f/fast_minimal_triangulation.c3),
[C++](../../../cpp/f/fast_minimal_triangulation.cpp),
[Elisa](../../../elisa/f/fast_minimal_triangulation.elisa),
[Mojo](../../../mojo/f/fast_minimal_triangulation.mojo),
[Nim](../../../nim/f/fast_minimal_triangulation.nim),
[Odin](../../../odin/f/fast_minimal_triangulation.odin),
[Rust](../../../rust/f/fast_minimal_triangulation.rs),
[V](../../../v/f/fast_minimal_triangulation.v), and
[Zig](../../../zig/f/fast_minimal_triangulation.zig).

The ten source ports, package metadata, workload and static helpers are in
place. Shared `i64_array_bytes_output` runner/verifier, root README, catalog,
and Chapter 142 crosswalk entries are integrated. No programs, tests, scripts,
checkers, builds, compilers, profilers, or benchmarks were run.
