# Minimum directed feedback arc set

This profile finds the fewest arcs whose removal makes a bounded directed
graph acyclic. A vertex order identifies a minimum set: remove every arc that
points backward in that order. Conversely, every feedback arc set leaves a DAG,
whose topological order has all remaining arcs pointing forward.

The primary algorithm is an exact prefix-subset dynamic program. For each
vertex subset `S`, `dp[S]` is the fewest backward arcs among orderings of `S`.
Appending vertex `v` costs the number of arcs `v -> u` with `u` already in
`S`. This runs in `O(N^2 2^N)` time and `O(2^N)` state space at the bound.
The independent oracle checks all `N!` vertex orders and counts backward arcs
directly.

This is distinct from [`undirected_feedback_vertex_set`](../../u/undirected_feedback_vertex_set/README.md),
which deletes vertices in an undirected graph, and from [`topological_sort`](../../t/topological_sort/README.md)
and [`directed_simple_cycles`](../../d/directed_simple_cycles/README.md),
which order DAGs or enumerate cycles rather than minimizing the number of
deleted directed arcs.

## Contract

- Exported symbol: `minimum_directed_feedback_arc_set`; ABI: `i64_array_scalar`.
- Input: `[N, M, (tail, head)*M]`, with `1 <= N <= 8` and `0 <= M <= 56`.
- The graph is simple directed: loops and duplicate ordered arcs are invalid;
  antiparallel arcs are allowed and are distinct arcs.
- Exact input length is `2 + 2*M`; malformed, null, out-of-range, duplicate,
  or trailing-word frames return `-1`.
- The result is an integer from `0` through `28`, equal to the minimum number
  of arcs whose deletion makes the graph acyclic. For a fixed prefix mask,
  vertices are considered in ascending ID order and states in ascending mask
  order; equal-cost predecessors keep the first encountered state. No witness
  ordering is emitted, so ties do not affect the result.
- Maximum valid and parseable lengths are 114 and 115 signed 64-bit words.

The recurrence and reduction are based on Bodlaender et al., [“A Note on Exact
Algorithms for Vertex Ordering Problems on Graphs”](https://doi.org/10.1007/s00224-011-9312-0),
Lemma 9 and the Held–Karp-style additive subset DP in Section 3. See
[`RIGHTS.md`](RIGHTS.md) for provenance.

## Language ports

[C](../../../c/m/minimum_directed_feedback_arc_set.c) ·
[C3](../../../c3/m/minimum_directed_feedback_arc_set.c3) ·
[C++](../../../cpp/m/minimum_directed_feedback_arc_set.cpp) ·
[Elisa](../../../elisa/m/minimum_directed_feedback_arc_set.elisa) ·
[Mojo](../../../mojo/m/minimum_directed_feedback_arc_set.mojo) ·
[Nim](../../../nim/m/minimum_directed_feedback_arc_set.nim) ·
[Odin](../../../odin/m/minimum_directed_feedback_arc_set.odin) ·
[Rust](../../../rust/m/minimum_directed_feedback_arc_set.rs) ·
[V](../../../v/m/minimum_directed_feedback_arc_set.v) ·
[Zig](../../../zig/m/minimum_directed_feedback_arc_set.zig)

The deterministic workload includes hand-derived cyclic, acyclic, antiparallel,
disjoint-cycle, overlapping-cycle, maximum-frame, and malformed inputs. The
references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py); the package-local inventory
reviewer is [`verify_workload.py`](verify_workload.py).
