# Dulmage–Mendelsohn decomposition

This profile computes the canonical three-way Dulmage–Mendelsohn (DM)
partition of a bounded bipartite graph. It describes how vertices can be
exposed across **all** maximum matchings, rather than returning one matching
or only its cardinality.

## Contract

- Exported symbol: `dulmage_mendelsohn_decomposition`; ABI:
  `i64_array_scalar`.
- Input: `[L,R,M,(left_id,right_id)*M]`, with `0<=L,R<=6`,
  `1<=L+R<=12`, and `0<=M<=L*R`. IDs are zero-based within each side.
- The graph is simple. Repeated pairs, invalid endpoints, malformed frames,
  null input, and trailing words return `-1`.
- Exact length is `3+2*M`; maximum valid and parseable lengths are 75 and 76
  signed 64-bit words.
- Output stores the maximum matching size in bits 32–35, then a two-bit class
  code per vertex in concatenated left-then-right order: `E=0`, `O=1`, `U=2`.
  The packed classes uniquely record the DM partition.

## Matching and partition

Compute a maximum matching. Start alternating-path searches from every
unmatched vertex, on either side. In an even state, traverse unmatched edges;
in an odd state, traverse matched edges. A vertex reached at even distance is
in `E`; one reached at odd distance is in `O`; a vertex reached at neither
parity is in `U`. For a maximum matching these sets are disjoint and their
partition does not depend on which maximum matching was found.

The primary uses ascending-neighbor Kuhn DFS followed by a two-parity BFS. The
independent reference enumerates all matchings in the small bounded graph to
find vertices that can be unmatched in a maximum matching (`E`); their
neighbors are `O`, and remaining vertices are `U`. The exhaustive reference
checks all at most 13,327 matchings for `K6,6`.

This is a decomposition of matching structure, distinct from
[`bipartite_matching_kuhn`](../../b/bipartite_matching_kuhn/README.md), which
reports a particular maximum matching. It also differs from minimum vertex
cover, which returns one dual certificate rather than the invariant E/O/U
classes.

## Provenance and rights

The method description and properties are from OI Wiki's [bipartite matching
article](https://github.com/OI-wiki/OI-wiki/blob/master/docs/graph/graph-matching/bigraph-match.md).
The foundational reference is A. L. Dulmage and N. S. Mendelsohn,
[“Coverings of Bipartite Graphs”](https://doi.org/10.4153/CJM-1958-052-0),
*Canadian Journal of Mathematics* 10 (1958), 517–534. Algorithm descriptions
and theorem attribution only are used; this bounded contract, workload,
oracles, and ports are clean-room. See [RIGHTS.md](RIGHTS.md).

## Ports and package files

[C](../../../c/d/dulmage_mendelsohn_decomposition.c) ·
[C3](../../../c3/d/dulmage_mendelsohn_decomposition.c3) ·
[C++](../../../cpp/d/dulmage_mendelsohn_decomposition.cpp) ·
[Elisa](../../../elisa/d/dulmage_mendelsohn_decomposition.elisa) ·
[Mojo](../../../mojo/d/dulmage_mendelsohn_decomposition.mojo) ·
[Nim](../../../nim/d/dulmage_mendelsohn_decomposition.nim) ·
[Odin](../../../odin/d/dulmage_mendelsohn_decomposition.odin) ·
[Rust](../../../rust/d/dulmage_mendelsohn_decomposition.rs) ·
[V](../../../v/d/dulmage_mendelsohn_decomposition.v) ·
[Zig](../../../zig/d/dulmage_mendelsohn_decomposition.zig)

Fixtures: [workload.json](workload.json). References:
[primary_oracle.py](primary_oracle.py) and
[independent_oracle.py](independent_oracle.py). Static inventory:
[verify_workload.py](verify_workload.py).
