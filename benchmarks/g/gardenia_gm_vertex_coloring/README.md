# GARDENIA Gebremedhin–Manne graph vertex coloring

This clean-room package profiles GARDENIA's iterative worklist coloring
algorithm at [`chenxuhao/gardenia`](https://github.com/chenxuhao/gardenia)
commit
[`5894df11cf47f8839945edadff43dc79e260216d`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d).
It follows the source `first_fit` and `conflict_resolve` phases in
`src/vc/linear_base.cu`, with the source contract documented in `src/vc/vc.h`.
The OpenMP host uses the same worklist phases but its first-fit helper indexes
the uncolored sentinel as a color; this bounded profile follows the source's
linear CUDA variant, which explicitly skips that sentinel.

## Bounded profile

Input is `[n, m, (u, v)...]` for a simple undirected graph, with
`1<=n<=16`, `0<=m<=64`, and canonical edges `u<v`. Each round assigns every
pending vertex the lowest color not used by its already-colored neighbors,
using a snapshot of colors from before the round. The conflict phase requeues
the lower-ID endpoint of every same-color edge and marks it uncolored; other
vertices keep their colors. The next round repeats until no conflict remains.
This preserves the source's speculative first-fit/worklist/recolor mechanics
with deterministic ascending-ID phase order. The independent verifier uses a
descending-ID greedy first-fit pass.

The output is one zero-based color per vertex, encoded as little-endian signed
i64. Invalid input returns `-1`; null or insufficient output returns `-2`
without writing. Since `n<=16`, the source's `MAXCOLOR=128` guard cannot be
reached by a valid input.

The pinned MIT notice is retained in [`LICENSE.txt`](LICENSE.txt). The nine
clean-room ports are listed below.

| Language | Source |
|---|---|
| C | [`c/g/gardenia_gm_vertex_coloring.c`](../../../c/g/gardenia_gm_vertex_coloring.c) |
| C3 | [`c3/g/gardenia_gm_vertex_coloring.c3`](../../../c3/g/gardenia_gm_vertex_coloring.c3) |
| C++ | [`cpp/g/gardenia_gm_vertex_coloring.cpp`](../../../cpp/g/gardenia_gm_vertex_coloring.cpp) |
| Elisa | [`elisa/g/gardenia_gm_vertex_coloring.elisa`](../../../elisa/g/gardenia_gm_vertex_coloring.elisa) |
| Nim | [`nim/g/gardenia_gm_vertex_coloring.nim`](../../../nim/g/gardenia_gm_vertex_coloring.nim) |
| Odin | [`odin/g/gardenia_gm_vertex_coloring.odin`](../../../odin/g/gardenia_gm_vertex_coloring.odin) |
| Rust | [`rust/g/gardenia_gm_vertex_coloring.rs`](../../../rust/g/gardenia_gm_vertex_coloring.rs) |
| V | [`v/g/gardenia_gm_vertex_coloring.v`](../../../v/g/gardenia_gm_vertex_coloring.v) |
| Zig | [`zig/g/gardenia_gm_vertex_coloring.zig`](../../../zig/g/gardenia_gm_vertex_coloring.zig) |

The package oracle is [`gardenia_gm_vertex_coloring_oracle.py`](../../gardenia_gm_vertex_coloring_oracle.py);
the independent verifier oracle is
[`gardenia_gm_vertex_coloring_verifier_oracle.py`](../../gardenia_gm_vertex_coloring_verifier_oracle.py).
