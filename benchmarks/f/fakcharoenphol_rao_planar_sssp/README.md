# Fakcharoenphol–Rao planar SSSP, bounded DDG profile

This benchmark computes one-source shortest distances on a small embedded
planar graph with negative arc lengths and no negative cycles. It follows the
Fakcharoenphol–Rao dense-distance-graph (DDG) construction and its
online Monge-block Dijkstra state machine. The caller supplies the recursive
piece hierarchy and the cyclic order of every piece boundary.

## Contract

The exported `fakcharoenphol_rao_planar_sssp` function uses the
`i64_array_bytes_output` ABI. Its input is
`[N, M, source, piece_count, (u,v,w)*M, piece_records...]`:

- `2 <= N <= 12`; `1 <= M <= 60` directed arcs. The underlying simple planar
  graph has at most one edge for `N=2` and at most `3N-6` otherwise. Each
  ordered endpoint pair appears at most once; an opposite arc is optional
  and has its own weight in `[-100,100]`. The underlying graph is connected.
  Inputs must have no negative directed cycle.
- Pieces are listed in postorder. A leaf record is
  `[-1,-1,arc_mask,boundary_count,boundary_ids...]` and contains at most
  three directed arcs. This is an explicit bounded constant-size exact DDG
  base case; the paper recurses to single-edge leaves. An internal record is
  `[left_child,right_child,-1,boundary_count,boundary_ids...]`; both child
  indices precede the parent. Leaf masks partition all `M` arcs. Every
  piece is connected; child vertex sets overlap on a separator, cover their
  parent, and each child has at most `ceil(2*parent_vertices/3)` vertices.
- A piece's vertex set is derived from its edges. Its boundary consists of
  vertices incident to an edge outside that piece, plus the source if the
  source belongs to the piece. Each boundary list must be an exact
  duplicate-free permutation of this set. The root boundary is the source.
- The embedding contract supplies each boundary's cyclic order. Every piece
  boundary must be cofacial in that order, and its directed DDG blocks must
  satisfy the Monge inequalities used by the algorithm. The ports verify
  the hierarchy, boundary sets, and Monge inequalities; planarity of the
  represented embedding is a valid-input precondition.
- Malformed input or a negative cycle returns `-1`. The output is `N`
  signed 64-bit distances in vertex order, encoded little-endian without a
  count prefix; unreachable vertices are `INT64_MAX`. The return value is
  the number of bytes written. A null
  output or insufficient capacity returns `-2` without writing. The maximum
  input is 2,088 words, output is 96 bytes, and conceptual workspace is
  bounded by 262,144 bytes.

## Bounded FR profile

For each internal piece, the implementation joins the two child DDGs, runs
one all-zero-source Bellman–Ford pass to obtain feasible potentials, and
reweights the DDG arcs. Each child's circular boundary is recursively split
into halves. Both directed cross-half distance matrices are represented as
Monge blocks, so every ordered pair of distinct boundary vertices appears in
one block. The block state tracks activated left rows, each unsettled right
column's best candidate, and settled columns. The piece-level Dijkstra loop
queries the minimum among tentative seed labels and block candidates, settles
that vertex across blocks, and activates its outgoing rows. This ordering
matters during expansion because one supplied boundary label can improve
another. Parent DDG distances are recorded from these reweighted runs and
converted back to original weights. A top-down pass uses
the same state machine to propagate the source labels to leaf pieces, where
the at-most-three-arc base graph supplies final vertex distances. Directed
DDG pairs without a path remain infinite; the output uses `INT64_MAX` for
unreachable vertices.

Boundary size is capped at 12. The ports implement `ActivateLeft`,
`FindNextMinNode`, and `AddCurrentMinNodeToS` with direct bounded scans. This
preserves the online Monge-block/Dijkstra state machine and exact output, but
does **not** implement the paper's amortized interval-tree/heap data structure
and makes no `O(N log^3 N)` time claim. For `P` pieces, `B <= 12` maximum
boundary size, and `M` original arcs, validation and the bounded profile
take `O(PMN + P B^4)` time and `O(P N^2 + PM + N)` auxiliary space. The
`B^4` term includes the explicit Monge-inequality checks; the online
activate/settle scans themselves take `O(B^3 log B)` per internal piece in
the worst case.

The primary reference checks the entire original directed graph for negative
cycles before following the recursive DDG and bounded online-block profile.
The independent oracle runs Bellman–Ford directly over the original
directed arc list. The workload exercises a two-level square decomposition
with negative arcs, a single-edge base case with an unreachable vertex,
negative-cycle rejection, boundary validation, and output-capacity handling. See
[`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py),
[`check_inventory.py`](check_inventory.py) for static source and fixture
validation, [`INVENTORY.md`](INVENTORY.md), and [`RIGHTS.md`](RIGHTS.md).

## Provenance and distinction

Fakcharoenphol and Rao define the recursive DDGs, feasible-potential
reweighting, Monge block partition, and online Dijkstra method for planar
graphs with negative edge weights. The bounded profile here keeps those
algorithmic structures while replacing their asymptotically optimized online
search data structure with direct scans at boundary size 12. It is distinct
from local general-graph Bellman–Ford, Johnson, and Dijkstra profiles, which
do not use a planar piece hierarchy or DDG Monge blocks.

Primary sources: Fakcharoenphol and Rao,
[“Planar graphs, negative weight edges, shortest paths, and near linear time”](https://doi.org/10.1016/j.jcss.2005.05.007)
([author PDF](https://theory.cpe.ku.ac.th/~jittat/papers/negcycle.pdf));
Henzinger, Klein, Rao, and Subramanian,
[“Faster Shortest-Path Algorithms for Planar Graphs”](https://doi.org/10.1006/jcss.1997.1493),
for recursive decomposition background; and the discovery entry,
[Encyclopedia of Algorithms DOI 372](https://doi.org/10.1007/978-0-387-30162-4_372).
The implementation is clean-room work; no source code, chapter prose, or
examples are copied.

## Language ports

Static-reviewed draft ports are available in all ten languages. Their source
paths and review status are tracked in [`INVENTORY.md`](INVENTORY.md). The
package is registered with the shared `i64_array_bytes_output` runner and
verifier. No ports, programs, tests, checkers, builds, or compilers were run.
