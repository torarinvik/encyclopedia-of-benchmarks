# Minimum bounded s–t flow

Given directed edges with lower and upper flow bounds, return the smallest
nonnegative flow value from `s` to `t` that satisfies every edge bound and
conserves flow at all other vertices. The primary applies the standard
lower-bound circulation reduction. It binary-searches a capacity `K` on an
auxiliary edge `t -> s`; each predicate tests whether a saturating maxflow
exists in the transformed network. The independent reference enumerates every
bounded integral edge-flow assignment and selects the least valid nonnegative
s–t value.

This measures the minimal-flow method from the CP-Algorithms
[“Flows with demands” article](https://cp-algorithms.com/graph/flow_with_demands.html).
The local
[`lower_bound_circulation_feasibility`](../lower_bound_circulation_feasibility/README.md)
package only decides circulation feasibility. The local
[`minimum_cost_b_flow`](../minimum_cost_b_flow/README.md) can encode the same
objective with a unit-cost return edge, but uses min-cost optimization rather
than repeated feasibility maxflows and binary search.

## Contract

The ABI is `i64_array_scalar`. Input is the signed-i64 sequence
`[n,m,s,t,(u,v,lower,upper)*m]`:

- `2 <= n <= 6`, `0 <= m <= 8`; `s` and `t` are distinct zero-based vertices
  in `[0,n)`.
- Each directed edge has zero-based endpoints in `[0,n)` and integer bounds
  `0 <= lower <= upper <= 2`. Parallel edges and self-loops are allowed.
- The exact frame length is `4+4*m`; the maximum valid frame is 36 words.
  Ports accept up to 37 words so an overlong frame can be rejected.
- These numeric limits define this bounded benchmark profile; the source
  article does not prescribe graph-size or capacity bounds.
- A valid result is the minimum nonnegative net outflow from `s` (equal to
  net inflow to `t`) among flows that conserve at every other vertex.
- `-1` means malformed or out-of-domain input. `-2` means the input is valid
  but no nonnegative `s`–`t` flow satisfies the bounds. Nonnegative results
  are flow values, including zero.

For each original edge `(u,v,lower,upper)`, initialize residual capacity
`upper-lower`, subtract `lower` from the balance at `u`, and add it at `v`.
Add the auxiliary `t -> s` edge with capacity `K`. For each positive balance,
add an edge from the super-source to that vertex; for each negative balance,
add an edge from that vertex to the super-sink. A maximum flow is feasible
exactly when it saturates all super-source edges. Edmonds–Karp uses matrix BFS
in these bounded ports.

The search upper bound is `U = sum upper` over non-self-loop edges leaving
`s`. Every nonnegative s–t flow value is at most this sum. Feasibility is
monotone in `K`, so the primary searches the integer range `[0,U]`; `U+1` is
the internal “no feasible value” sentinel. Here `U<=16`, so the search uses at
most five maxflow predicates. The transformed graph has at most eight vertices
and at most `m+n+1<=15` forward arcs, including the auxiliary return edge.
Each matrix BFS scans at most 64 cells. A predicate costs
`O(V^3 E)` with Edmonds–Karp and matrix BFS; the complete profile costs
`O(log(U+2) V^3 E)` time and uses at most 1,024 bytes of internal scratch.
The scalar ABI has no caller-provided output or workspace buffer; workload
`workspace_bytes` therefore records zero external workspace per call.

The independent oracle enumerates at most `3^8 = 6,561` edge assignments,
checks conservation at internal vertices and equal opposite terminal balances,
and minimizes only over nonnegative flow values. The workload includes a
transformed instance whose first augmenting path must be rerouted through a
reverse residual edge to saturate all super-source arcs. See
[`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and
[`workload.json`](workload.json). The method description is attributed in
[`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_bounded_s_t_flow.c`](../../../c/m/minimum_bounded_s_t_flow.c) |
| C3 | [`c3/m/minimum_bounded_s_t_flow.c3`](../../../c3/m/minimum_bounded_s_t_flow.c3) |
| C++ | [`cpp/m/minimum_bounded_s_t_flow.cpp`](../../../cpp/m/minimum_bounded_s_t_flow.cpp) |
| Elisa | [`elisa/m/minimum_bounded_s_t_flow.elisa`](../../../elisa/m/minimum_bounded_s_t_flow.elisa) |
| Mojo | [`mojo/m/minimum_bounded_s_t_flow.mojo`](../../../mojo/m/minimum_bounded_s_t_flow.mojo) |
| Nim | [`nim/m/minimum_bounded_s_t_flow.nim`](../../../nim/m/minimum_bounded_s_t_flow.nim) |
| Odin | [`odin/m/minimum_bounded_s_t_flow.odin`](../../../odin/m/minimum_bounded_s_t_flow.odin) |
| Rust | [`rust/m/minimum_bounded_s_t_flow.rs`](../../../rust/m/minimum_bounded_s_t_flow.rs) |
| V | [`v/m/minimum_bounded_s_t_flow.v`](../../../v/m/minimum_bounded_s_t_flow.v) |
| Zig | [`zig/m/minimum_bounded_s_t_flow.zig`](../../../zig/m/minimum_bounded_s_t_flow.zig) |
