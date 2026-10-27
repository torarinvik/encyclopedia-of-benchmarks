# Goemans–Williamson Max-Cut hyperplane rounding

This bounded profile implements the hyperplane-rounding step described in the
“Max Cut” chapter: a vertex goes to side 1 when its supplied SDP vector has a
positive dot product with the supplied hyperplane normal, and otherwise goes
to side 0. The zero case uses side 0 for determinism. It then reports the
weight of the resulting cut.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[n, m, d, (u, v, weight)..., vector[n][d], normal[d]]`. Edges are simple,
undirected, positive-weight pairs in strictly increasing `(u,v)` order.
There are 2–16 vertices, at most 120 edges, and 1–4 dimensions. Vector
coordinates and the nonzero hyperplane normal have magnitude at most 100; all
vertex vectors must have the same nonzero squared norm. The output is
`[cut_weight, side_0, ..., side_(n-1)]` as little-endian i64 values. Invalid
input returns `-1`; null or undersized output returns `-2` without writing.

## Scope

The chapter's SDP solver, construction of a feasible unit-vector solution,
random hyperplane generation, and expected approximation guarantee are not
part of this deterministic supplied-input profile. The input normal represents
one fixed hyperplane direction; no probability or approximation claim is made.
This rounding kernel is distinct from the chapter's Sahni–Gonzalez greedy
half-approximation in [`max_cut_sahni_gonzalez`](../max_cut_sahni_gonzalez/README.md).

## Source and clean-room status

The source is the “Max Cut” entry, DOI
[`10.1007/978-1-4939-2864-4_219`](https://doi.org/10.1007/978-1-4939-2864-4_219).
All implementations are clean-room and use no copied book prose or code.

## Language ports

| Language | Source |
|---|---|
| C | `c/m/max_cut_gw_rounding.c` |
| C3 | `c3/m/max_cut_gw_rounding.c3` |
| C++ | `cpp/m/max_cut_gw_rounding.cpp` |
| Elisa | `elisa/m/max_cut_gw_rounding.elisa` |
| Nim | `nim/m/max_cut_gw_rounding.nim` |
| Odin | `odin/m/max_cut_gw_rounding.odin` |
| Rust | `rust/m/max_cut_gw_rounding.rs` |
| V | `v/m/max_cut_gw_rounding.v` |
| Zig | `zig/m/max_cut_gw_rounding.zig` |
