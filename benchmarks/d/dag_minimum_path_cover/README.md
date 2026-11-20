# Minimum path cover in a DAG

This bounded profile finds a minimum collection of vertex-disjoint directed
paths that covers every vertex of a directed acyclic graph. It uses the
standard reduction from DAG path cover to bipartite matching. The matching
routine is the reduction's subroutine; the profile measures building the
split graph, finding a maximum matching, and reconstructing the path cover.

## Contract

- Exported symbol: `dag_minimum_path_cover`; ABI: `i64_array_scalar`.
- Input: `[N,M,(u,v)*M]`, with `1 <= N <= 10`, `0 <= M <= 45`, and zero-based
  vertices. The graph must be simple and acyclic; loops and repeated arcs are
  invalid.
- Exact length: `2 + 2*M`; maximum valid and parseable lengths are 92 and 93
  words. Invalid or null input returns `-1`.
- The output packs the path count in bits 40–43 and one 4-bit successor per
  vertex in ascending vertex order. `N` is the path-end marker. This uniquely
  records the returned cover for every accepted graph. The declared scalar
  ceiling uses path count `10` and the full 40-bit successor field; it is a
  conservative encoding bound, while each actual successor is at most `N`.

## Reduction and deterministic cover

Make a left and right copy of each DAG vertex. For every arc `u -> v`, connect
`u_left` to `v_right`. A matching selects at most one outgoing and one
incoming arc per vertex. Since the input is acyclic, the selected arcs form
vertex-disjoint paths, not cycles. If the maximum matching has size `K`, the
cover has `N-K` paths.

The profile chooses one canonical maximum matching so its successor-map
encoding is stable. In vertex order, it fixes the smallest available outgoing
neighbor that still permits a matching of maximum cardinality; if none can be
fixed, it chooses the path-end marker. All ten ports and the primary reference
use deterministic Kuhn DFS augmenting paths for each cardinality check. The
independent reference uses a suffix dynamic program over subsets of right
vertices.

The bounded canonicalization takes `O((M+N) N M)` primary work and
`O((N+M) 2^N)` independent-reference work. This package does not claim to
introduce a new maximum-matching primitive; it benchmarks the DAG reduction
and reconstructs an explicit minimum path cover. The existing matching
packages accept an arbitrary bipartite graph and return matching outputs,
whereas this profile validates a DAG and returns a canonical path cover.

## Provenance and rights

The reduction and path-cover theorem are described in the OI Wiki
[maximum bipartite matching article](https://oi-wiki.org/graph/graph-matching/bigraph-match/).
Fulkerson's 1956 note gives the matching-based decomposition argument for
Dilworth's theorem: [DOI 10.1090/S0002-9939-1956-0078334-6](https://doi.org/10.1090/S0002-9939-1956-0078334-6).
Only algorithm descriptions and theorem attribution are used. The bounded
contract, canonical tie policy, workload, references, and ports are clean-room.
See [RIGHTS.md](RIGHTS.md).

## Ports and package files

[C](../../../c/d/dag_minimum_path_cover.c) ·
[C3](../../../c3/d/dag_minimum_path_cover.c3) ·
[C++](../../../cpp/d/dag_minimum_path_cover.cpp) ·
[Elisa](../../../elisa/d/dag_minimum_path_cover.elisa) ·
[Mojo](../../../mojo/d/dag_minimum_path_cover.mojo) ·
[Nim](../../../nim/d/dag_minimum_path_cover.nim) ·
[Odin](../../../odin/d/dag_minimum_path_cover.odin) ·
[Rust](../../../rust/d/dag_minimum_path_cover.rs) ·
[V](../../../v/d/dag_minimum_path_cover.v) ·
[Zig](../../../zig/d/dag_minimum_path_cover.zig)

Fixtures: [workload.json](workload.json). References:
[primary_oracle.py](primary_oracle.py) and
[independent_oracle.py](independent_oracle.py). Static inventory:
[verify_workload.py](verify_workload.py).
