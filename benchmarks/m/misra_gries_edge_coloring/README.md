# Misra–Gries/Vizing edge coloring

This bounded benchmark colors a simple undirected graph with `Delta+1` colors
using the fan, alternating-path inversion, and fan-rotation procedure from
Misra and Gries. It covers general graphs; it does not promise a minimum
color count.

## Contract

The exported `i64_array_scalar` function is
`misra_gries_edge_coloring(const int64_t *input, size_t length)`. Input is
`[N,M,(u,v)*M]`, with `1<=N<=6`, `0<=M<=6`, and vertices `0..N-1`. The graph
must be loopless and simple; duplicate unordered edges are invalid. Preserve
input edge order as the output edge order, while each pair is normalized to
`(min(u,v),max(u,v))` and its lower endpoint is the fan center. The exact frame
length is `2+2*M`; maximum valid and parseable lengths are 14 and 15 words.
Null, malformed, out-of-range, duplicate, loop, and trailing input return
`-1`.

Color edges in input order. For each uncolored edge `X-Y`, start a fan with
`Y`; repeatedly append the lowest-ID neighbor of `X` not already in the fan
whose colored `X-v` edge color is free at the current fan tail. Choose the
smallest color `c` free at `X` and smallest color `d` free at the final fan
vertex. Invert the maximal alternating `c/d` path containing `X`, choose the
lowest-index fan prefix whose final vertex has `d` free, rotate its colors
toward the uncolored first fan edge, then color the newly uncolored edge `d`.
The paper leaves several choices nondeterministic; the stated ascending scans
pin this profile.

The result is `palette_size*8^6 + color_signature`. The high field is
`Delta+1` for nonempty graphs and zero when there are no edges. Six low
3-bit fields encode colors in input order; unused fields are zero. Colors lie
in `0..Delta`, so the field fits. A safe upper bound is
`6*8^6+5*(8^6-1)/7=1,760,109`, using six palette colors and the sum of the
six 3-bit-place values. The primary uses direct incidence scans in
`O(M*N^3)` time and `O(N^2+M)` space. The structurally independent reference
checks the returned coloring certificate from its decoded fields in
`O(N+M)` time and space.

This is distinct from [`bipartite_edge_coloring`](../../b/bipartite_edge_coloring/README.md),
which finds a minimum-`Delta` coloring for bipartite multigraphs, and
[`tree_min_cost_proper_coloring`](../../t/tree_min_cost_edge_coloring/README.md),
which optimizes shared color costs on trees.

## Sources and rights

The primary source is Misra and Gries, [“A Constructive Proof of Vizing’s
Theorem”](https://doi.org/10.1016/0020-0190(92)90041-S), also available as an
[author-hosted PDF](https://www.cs.utexas.edu/~misra/psp.dir/vizing.pdf).
KACTL’s [graph chapter](https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/chapter.tex)
imports its CC0 [`EdgeColoring.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/EdgeColoring.h),
used here as the catalog reference. Only the algorithmic ideas are used; all
code, workload, tie choices, and explanations are independently authored.
See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [misra_gries_edge_coloring.c](../../../c/m/misra_gries_edge_coloring.c) |
| C3 | [misra_gries_edge_coloring.c3](../../../c3/m/misra_gries_edge_coloring.c3) |
| C++ | [misra_gries_edge_coloring.cpp](../../../cpp/m/misra_gries_edge_coloring.cpp) |
| Elisa | [misra_gries_edge_coloring.elisa](../../../elisa/m/misra_gries_edge_coloring.elisa) |
| Mojo | [misra_gries_edge_coloring.mojo](../../../mojo/m/misra_gries_edge_coloring.mojo) |
| Nim | [misra_gries_edge_coloring.nim](../../../nim/m/misra_gries_edge_coloring.nim) |
| Odin | [misra_gries_edge_coloring.odin](../../../odin/m/misra_gries_edge_coloring.odin) |
| Rust | [misra_gries_edge_coloring.rs](../../../rust/m/misra_gries_edge_coloring.rs) |
| V | [misra_gries_edge_coloring.v](../../../v/m/misra_gries_edge_coloring.v) |
| Zig | [misra_gries_edge_coloring.zig](../../../zig/m/misra_gries_edge_coloring.zig) |
