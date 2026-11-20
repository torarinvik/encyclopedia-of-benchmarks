# Minimum dominating set by branch and bound

This profile finds the smallest vertex set that contains or neighbors every
vertex in a simple undirected graph. Its primary algorithm starts with a
deterministic greedy solution, then searches from an uncovered vertex. Every
valid dominating set must contain that vertex or one of its neighbors, so the
search branches over its closed neighborhood. A coverage bound prunes a state
when even the maximum possible new coverage cannot improve the incumbent.

The independent reference enumerates vertex subsets by increasing size and
checks their closed-neighborhood union. The profile is distinct from
[`weighted_connected_dominating_set`](../../w/weighted_connected_dominating_set/README.md),
which minimizes positive weights and requires the chosen vertices to induce a
connected graph; from [`tree_weighted_dominating_set`](../../t/tree_weighted_dominating_set/README.md),
which is restricted to trees and has weighted input; and from
[`minimal_dominating_sets_interval`](../../m/minimal_dominating_sets_interval/README.md),
which counts inclusion-minimal solutions on interval graphs.

## Contract

- Exported symbol: `minimum_dominating_set_branch_bound`; ABI: `i64_array_scalar`.
- Input: `[N, M, (u, v)*M]`, with `1 <= N <= 12` and
  `0 <= M <= N(N-1)/2`.
- The graph is simple and undirected. Each unordered pair appears once, with
  either endpoint order accepted. Loops, repeated edges, invalid endpoints,
  malformed frames, null input, and trailing words
  return `-1`.
- Output is the minimum dominating-set cardinality, from `1` through `12`.
- Exact input length is `2 + 2*M`; maximum valid and parseable lengths are 134
  and 135 signed 64-bit words.
- Greedy choices scan vertices in ascending ID order and keep the first maximum
  gain. Search chooses the lowest-ID uncovered vertex among those with minimum
  closed-neighborhood size; candidate vertices are tried by decreasing new
  coverage, then ascending ID. The result does not expose a witness set.

The branch-and-bound approach is an idea reference from Jiang and Zheng,
[“An Exact Algorithm for the Minimum Dominating Set Problem”](https://doi.org/10.24963/ijcai.2023/622).
This benchmark uses its own bounded search rule; see [`RIGHTS.md`](RIGHTS.md).

## Language ports

[C](../../../c/m/minimum_dominating_set_branch_bound.c) ·
[C3](../../../c3/m/minimum_dominating_set_branch_bound.c3) ·
[C++](../../../cpp/m/minimum_dominating_set_branch_bound.cpp) ·
[Elisa](../../../elisa/m/minimum_dominating_set_branch_bound.elisa) ·
[Mojo](../../../mojo/m/minimum_dominating_set_branch_bound.mojo) ·
[Nim](../../../nim/m/minimum_dominating_set_branch_bound.nim) ·
[Odin](../../../odin/m/minimum_dominating_set_branch_bound.odin) ·
[Rust](../../../rust/m/minimum_dominating_set_branch_bound.rs) ·
[V](../../../v/m/minimum_dominating_set_branch_bound.v) ·
[Zig](../../../zig/m/minimum_dominating_set_branch_bound.zig)

The bounded cases are in [`workload.json`](workload.json). References are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py); the static source and
documentation inventory is [`verify_workload.py`](verify_workload.py).
