# GraphAI GNNS hill climbing

This package is a clean-room bounded profile of graph-guided approximate
nearest-neighbor hill climbing. It is distinct from the local
[`nearest_neighbour_search`](../../n/nearest_neighbour_search/README.md), which
walks a KD-tree to produce an exact nearest point.

The profile follows the query shape described for GNNS by Hajebi et al.: a
prebuilt directed k-nearest-neighbor graph, a query, a start node, and bounded
neighbor expansion and greedy-step controls. The offline k-NN graph
construction is **supplied as input and is not benchmarked**. Search uses one
supplied starting node, which models one start/restart (`R=1`); it does not
sample a random start. The requested result count is fixed at `K=1`, and the
profile terminates at a local minimum or after the supplied step budget `T`.
The GNNS source paper describes Euclidean distance and selecting the first
`E` outgoing neighbors; this bounded profile fixes the neighbor order as
ascending vertex ID so the supplied graph can use compact adjacency masks.
That ordering is a deterministic profile choice, not a claim about
GraphAIBench's implementation.

The input is `[N,D,start,E,T, point_coordinates[N*D], outgoing_masks[N],
query[D]]`. Bounds are `2<=N<=16`, `1<=D<=4`, `0<=start<N`,
`1<=E<=N-1`, `0<=T<=16`, and coordinates in `[-100,100]`. Each outgoing mask
may contain only IDs in `0..N-1`, and its diagonal bit must be clear. Exact
length is `5+N*D+N+D`; the maximum valid and parseable lengths are 89 and 90.
Invalid and null inputs return `-1`.

At each step, search inspects at most the first `E` outgoing neighbors in
ascending ID order, evaluates squared Euclidean distance to the query, and
chooses the candidate minimizing `(distance,vertex_id)`. It moves only when
that candidate is **strictly closer** than the current node; an equal-distance
tie never moves. The search then repeats from the new node. There is no
visited-node filter: because every move strictly decreases distance, a node
cannot be revisited. The distance-evaluation count includes the initial node
and every inspected neighbor. The scalar packs evaluations, moves, final node,
and final squared distance as
`(((evaluations*17+moves)*16+final_node)*160001+distance_squared)`.

The primary oracle scans adjacency masks; the independent verifier converts
them into sorted adjacency lists and reduces each frontier to its minimum
`(distance,vertex_id)` pair. Ten language ports use the `i64_array_scalar`
ABI. Both oracles and fixture review are included; the suite supplies
additional bounded valid and invalid frames.

## Source and scope

Kiana Hajebi, Yasin Abbasi-Yadkori, Hossein Shahbazi, and Hong Zhang, “Fast
Approximate Nearest-Neighbor Search with k-Nearest Neighbor Graph,” IJCAI
2011, pp. 1312–1316, [official proceedings page and paper
PDF](https://ijcai.org/proceedings/2011/222),
[DOI 10.5591/978-1-57735-516-8/IJCAI11-222](https://doi.org/10.5591/978-1-57735-516-8/IJCAI11-222).
The paper supplies algorithm provenance only. GraphAIBench's pinned
`src/nearest_neighbor_search/omp_base.cc` contains an empty per-vertex stub
(`// add code here`), so this profile does **not** port or reproduce a
GraphAIBench implementation. The query contract, fixtures, oracles, and ports
are independently written.
