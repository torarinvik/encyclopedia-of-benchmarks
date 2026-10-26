# Vertex-cover degree-reduction kernel

This package exposes the source chapter's deterministic degree-based
preprocessing for the parameterized vertex-cover decision problem. It is a
bounded reduction stage, not a complete vertex-cover solver and not the
chapter's Nemhauser–Trotter or crown-reduction procedures.

Input is `[n,m,k,(u,v)...]` with `1 <= n <= 16`, `0 <= m <= 64`, and
`0 <= k <= 16`. Edges are simple, undirected, and supplied once in strictly
increasing canonical order with `u < v`. The reduction repeatedly applies
these rules in a fixed order: remove the lowest-ID isolated active vertex;
otherwise, for the lowest-ID degree-one vertex, force its only neighbor into
the cover; otherwise, force the lowest-ID vertex whose degree exceeds the
remaining parameter. A forced vertex is removed with all incident edges and
decrements `k`. The degree-one rule is safe because if a cover contains the
leaf instead of its neighbor, replacing the leaf by that neighbor preserves
coverage without increasing the cover size. The high-degree rule is forced:
excluding the vertex would require more than `k` neighbors.

Output is `[status,remaining_k,forced_vertex_mask,active_vertex_mask,edge_count,
(u,v)...]`. Status is `1` for the reduced equivalent instance and `0` when the
forced choices exceed the parameter. Vertex IDs in masks and residual edges
refer to the original graph. Output is little-endian signed i64; maximum output
is 1064 bytes. Invalid input returns `-1`; null output or insufficient capacity
returns `-2`, without writing.

Source: “Vertex Cover Kernelization,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_460`](https://doi.org/10.1007/978-1-4939-2864-4_460).
This package implements a clean-room bounded projection of the chapter's
degree preprocessing; it does not copy book prose or source code.

## Ports

| Language | Port |
|---|---|
| C | `c/v/vertex_cover_kernelization.c` |
| C3 | `c3/v/vertex_cover_kernelization.c3` |
| C++ | `cpp/v/vertex_cover_kernelization.cpp` |
| Elisa | `elisa/v/vertex_cover_kernelization.elisa` |
| Nim | `nim/v/vertex_cover_kernelization.nim` |
| Odin | `odin/v/vertex_cover_kernelization.odin` |
| Rust | `rust/v/vertex_cover_kernelization.rs` |
| V | `v/v/vertex_cover_kernelization.v` |
| Zig | `zig/v/vertex_cover_kernelization.zig` |

The exact-output oracle is `benchmarks/vertex_cover_kernelization_oracle.py`;
the independent verifier oracle is
`benchmarks/vertex_cover_kernelization_verifier_oracle.py`.
