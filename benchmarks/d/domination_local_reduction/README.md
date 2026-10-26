# Local domination data reduction

This package implements the single-neighborhood reduction described in
Chapter 99 of the *Encyclopedia of Algorithms*. For a chosen pivot `v`, its
neighbors are classified as exits (`N1`, with a neighbor outside the closed
neighborhood of `v`), guards (`N2`, the remaining neighbors adjacent to an
exit), and prisoners (`N3`, all other neighbors). The operation is applicable
when `N3` is nonempty: delete `N2 ∪ N3`, preserve the induced graph on all
remaining original vertices, and append a fresh leaf joined to `v`.

## Contract

ABI: `i64_array_bytes_output`; symbol `domination_local_reduction`. Input is
`[n,m,pivot,(u,v)...]`, with `1 <= n <= 12`, `0 <= m <= 66`, and simple
undirected edges encoded once with `u < v`. The pivot is in `[0,n)`. An input
is valid only when the computed `N3` is nonempty. Invalid or inapplicable
inputs return `-1`.

Output is little-endian signed 64-bit words:
`[k, old_id_0, ..., old_id_(k-2), -1, rowmask_0, ..., rowmask_(k-1)]`.
The original surviving vertices appear in ascending ID order; `-1` identifies
the appended gadget leaf, which is last. Each row mask uses bit `j` for an edge
to output vertex `j`. Success returns `8*(1+2*k)` bytes. Null output or
insufficient capacity returns `-2` without writing. Maximum input length is
135 words and maximum output is 200 bytes.

This is one local reduction step, not the chapter's full planar-graph kernel
or its second rule for diamond structures. It exposes the transformed graph
for reproducibility; it does not solve Dominating Set.

## Source and rights

Based on the abstract rule in Chapter 99, “Data Reduction for Domination in
Graphs,” DOI [10.1007/978-1-4939-2864-4_99](https://doi.org/10.1007/978-1-4939-2864-4_99).
All ports are clean-room implementations of the stated graph operation. The
book remains copyrighted by Springer; no book text, source code, or figures
are copied, and attribution is not a grant to redistribute book contents.
See [`RIGHTS.md`](RIGHTS.md) for the explicit rights note.

Primary oracle: [`domination_local_reduction_oracle.py`](../../domination_local_reduction_oracle.py).
Independent verifier: [`domination_local_reduction_verifier_oracle.py`](../../domination_local_reduction_verifier_oracle.py).

| Language | Source |
|---|---|
| C | [`c/d/domination_local_reduction.c`](../../../c/d/domination_local_reduction.c) |
| C3 | [`c3/d/domination_local_reduction.c3`](../../../c3/d/domination_local_reduction.c3) |
| C++ | [`cpp/d/domination_local_reduction.cpp`](../../../cpp/d/domination_local_reduction.cpp) |
| Elisa | [`elisa/d/domination_local_reduction.elisa`](../../../elisa/d/domination_local_reduction.elisa) |
| Nim | [`nim/d/domination_local_reduction.nim`](../../../nim/d/domination_local_reduction.nim) |
| Odin | [`odin/d/domination_local_reduction.odin`](../../../odin/d/domination_local_reduction.odin) |
| Rust | [`rust/d/domination_local_reduction.rs`](../../../rust/d/domination_local_reduction.rs) |
| V | [`v/d/domination_local_reduction.v`](../../../v/d/domination_local_reduction.v) |
| Zig | [`zig/d/domination_local_reduction.zig`](../../../zig/d/domination_local_reduction.zig) |
