# Canonical order of a maximal plane triangulation

This package profiles the reverse shelling procedure for a canonical order in
Chapter 650's “Canonical Order” subsection. It accepts an already embedded
maximal plane triangulation; planarity testing and embedding construction are
outside the profile.

Input is a signed-i64 array:

```text
[n, u, v, w, (degree[x], clockwise_neighbors[x]...) for x=0..n-1]
```

There are 3 through 8 vertices with IDs `0..n-1`. Every row lists each
neighbor once in clockwise rotation order. The undirected graph must be simple,
connected, and maximal planar; the rotations must form a spherical embedding
whose directed face walk from `u` to `v` to `w` returns to `u`. The ordered
outer-face vertices `u,v,w` are distinct. Face walking follows the next
clockwise neighbor after the incoming edge. Rotations can be cyclically shifted
without changing the embedding. The input length is `4 + n + sum(degree)`, at
most 48 words; 49 words are accepted to classify one trailing word as invalid.

The source procedure fixes `v_n=w` and repeatedly removes a vertex from the
current outer-boundary path from `u` to `v`, leaving a 2-connected prefix. If
the path has no chord, it permits any interior boundary vertex. If chords are
present, it chooses an inclusion-minimal chord and removes any boundary vertex
strictly between its endpoints. This package makes those choices deterministic:
when there are no chords it chooses the eligible vertex with the smallest ID;
otherwise it considers the interior vertices of every inclusion-minimal chord
(containment is by the current boundary indices) and chooses the smallest ID.
After three vertices remain, the canonical order is `[u,v,v3,...,vn]`, with
the removal trace reversed after `v3`.

Output is little-endian signed-i64 words `[n, canonical_order...]`, at most 72
bytes. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` and leaves output untouched. Workspace is 4096 bytes. The ports
validate the small rotation system, face triangles, outer face, and chord rule
with bounded scans; their actual worst-case work is `O(n^5)` for `n<=8` because
each peel rescans candidate chord intervals for inclusion-minimality. The
chapter explains how chord-incidence counters and neighbor updates reduce the
construction to linear time; this bounded profile uses repeated scans instead.

The primary reference performs the theorem's reverse boundary peeling and
applies the deterministic tie rule. The independent reference recursively
enumerates all source-permitted peel choices and selects the lexicographically
smallest reverse trace, then checks the canonical-order prefix conditions by
direct connectivity and boundary-neighbor tests. The algorithm returns an
ordering only; it does not draw coordinates or compute a Schnyder realizer.
This is distinct from local triangulation constructors, the 3D moment-curve
drawing, and Sugiyama's ordering of an already layered DAG.

Source: “Canonical Orders and Schnyder Realizers,” *Encyclopedia of
Algorithms*, [Chapter 650](https://doi.org/10.1007/978-1-4939-2864-4_650),
Canonical Order subsection, Definition 1 and Theorem 1 proof. Only algorithm
descriptions are used; code and fixtures are clean-room.

## Ports

| Language | Source |
|---|---|
| C | `c/c/canonical_order_maximal_plane_triangulation.c` |
| C3 | `c3/c/canonical_order_maximal_plane_triangulation.c3` |
| C++ | `cpp/c/canonical_order_maximal_plane_triangulation.cpp` |
| Elisa | `elisa/c/canonical_order_maximal_plane_triangulation.elisa` |
| Mojo | `mojo/c/canonical_order_maximal_plane_triangulation.mojo` |
| Nim | `nim/c/canonical_order_maximal_plane_triangulation.nim` |
| Odin | `odin/c/canonical_order_maximal_plane_triangulation.odin` |
| Rust | `rust/c/canonical_order_maximal_plane_triangulation.rs` |
| V | `v/c/canonical_order_maximal_plane_triangulation.v` |
| Zig | `zig/c/canonical_order_maximal_plane_triangulation.zig` |

`primary_oracle.py` follows the reverse-shelling rule;
`independent_oracle.py` uses bounded recursive enumeration and direct prefix
validation. `check_inventory.py` is a static package/source inventory checker.
