# Canonical-order Schnyder realizer

This package converts a supplied canonical order of a maximal plane
triangulation into the chapter's three colored parent-edge assignments. The
input includes the same clockwise rotation system and outer roots as
`canonical_order_maximal_plane_triangulation`, followed by the proposed order:

```text
[n,u,v,w,(degree[x],clockwise_neighbors[x]...)*n,order[0..n)]
```

Vertex IDs are `0..n-1`, with `3 <= n <= 8`. The rotation rows describe a
simple connected maximal plane triangulation. The directed face walk
`u -> v -> w -> u` selects the outer triangle; rotations may be cyclically
shifted. The order must be a permutation beginning `u,v` and ending `w`, and
must satisfy the canonical prefix conditions for this embedding. The largest
valid frame is 56 signed-i64 words. A 57-word frame is parseable only to
classify its trailing word as invalid.

The rows use the existing canonical-order package's face-walk successor
orientation, where the directed selected outer face is `u,v,w`. For the
Chapter 650 clockwise local incidence rule with those roots in counterclockwise
order, the references traverse each stored rotation row in reverse. This is a
cyclic-direction conversion for the local rule; the input frame and face walk
are unchanged.

The output is little-endian signed-i64 words
`[n,(vertex,parent_T1,parent_T2,parent_T3)*]`, with exactly `n-3` records in
increasing canonical-order position. The three outer roots are omitted. For
each interior vertex, `parent_T1` is its leftmost earlier neighbor on the
current `u`-to-`v` boundary, `parent_T2` is its rightmost earlier neighbor,
and `parent_T3` is its highest-labeled later neighbor. Boundary order runs
from `u` to `v`. Thus T1 is rooted at `u`, T2 at `v`, and T3 at `w`, matching
the chapter's three outer-root convention. Each returned parent is an edge.
Both references verify one parent per color, root-reaching parent chains, and
that the colored parent edges partition all non-outer edges. The maximum
output is 168 bytes. Invalid input or a noncanonical order returns `-1`;
null output or insufficient capacity returns `-2` without writing output.
Workspace is 4096 bytes. Repeated bounded face, prefix, and parent scans cost
`O(n^5)` in the accepted profile (`n<=8`).

The primary reference checks the supplied order through reverse shelling: it
peels the interior vertices in reverse order, applying the source's
chord-free and inclusion-minimal-chord rules, then derives the three parent
roles. The independent reference checks every forward prefix directly using
its boundary path, connectivity after each possible vertex deletion, and
contiguous earlier-neighbor interval; it then reconstructs and verifies the
colored trees separately. Both references check the chapter's clockwise
six-run condition `out T1, in T2, out T3, in T1, out T2, in T3`, allowing
empty incoming runs after the documented row-direction conversion.

## Source and distinction

Source: “Canonical Orders and Schnyder Realizers,” *Encyclopedia of
Algorithms*, [Chapter 650](https://doi.org/10.1007/978-1-4939-2864-4_650),
“Schnyder Realizer” and “Equivalency of Canonical Orders and Schnyder
Realizers,” Lemma 3. The ports use the algorithm description and lemma only;
implementations and fixtures are clean-room. This output is distinct from the
chapter's canonical-order construction, which returns an ordering, and from
local planar embedding or drawing packages, which return embeddings or
coordinates.

## Ports

| Language | Source |
|---|---|
| C | `c/c/canonical_order_schnyder_realizer.c` |
| C3 | `c3/c/canonical_order_schnyder_realizer.c3` |
| C++ | `cpp/c/canonical_order_schnyder_realizer.cpp` |
| Elisa | `elisa/c/canonical_order_schnyder_realizer.elisa` |
| Mojo | `mojo/c/canonical_order_schnyder_realizer.mojo` |
| Nim | `nim/c/canonical_order_schnyder_realizer.nim` |
| Odin | `odin/c/canonical_order_schnyder_realizer.odin` |
| Rust | `rust/c/canonical_order_schnyder_realizer.rs` |
| V | `v/c/canonical_order_schnyder_realizer.v` |
| Zig | `zig/c/canonical_order_schnyder_realizer.zig` |

`primary_oracle.py` and `independent_oracle.py` are bounded Python references.
`check_inventory.py` checks the package inventory, provenance, workload
fixtures, and presence of the ten source paths without compiling or running
the ports.
