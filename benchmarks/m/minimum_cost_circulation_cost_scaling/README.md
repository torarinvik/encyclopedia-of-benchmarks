# Goldberg–Tarjan minimum-cost circulation cost scaling

This profile minimizes the cost of an integral circulation by tightening an
epsilon-optimality bound. Each refinement halves epsilon, saturates negative
reduced-cost residual arcs, then restores flow conservation with admissible
pushes and price relabels. It is distinct from local successive-shortest-path
min-cost flow and negative-cycle cancellation: cost scaling repeatedly
switches between a pseudoflow and a feasible circulation while preserving the
reduced-cost invariant.

## Contract

Input is `[n,m,(u,v,capacity,cost)*m]`, with `1<=n<=8`, `0<=m<=10`,
zero-based endpoints, capacities in `0..2`, and costs in `[-4,4]`. Parallel
arcs and self-loops are allowed. The exact frame is `2+4*m` signed-i64 words.
Zero flow is always a feasible circulation. The exact minimum cost is in
`[-80,80]`; the scalar result is `minimum_cost + 81`, so valid outputs are
`1..161`. Invalid input returns `-1`.

Integer costs are scaled by `n+1`. Prices define reduced cost
`c(u,v)+p(u)-p(v)`; a residual arc is admissible when that value is negative.
Positive excess means excess inflow. A relabel sets
`p(v)=max(p(w)-c(v,w)-epsilon)` over residual outgoing arcs. Each operation
preserves epsilon-optimality, and the final 1-optimal circulation is optimal
for the original integral costs. The simple generic method has
`O(n^3 log(nC))` time; this workload bounds capacities, edges, and costs.

The primary oracle implements scaled push–relabel refinement. An independent
oracle enumerates every bounded edge-flow assignment, checks conservation,
and selects the least-cost circulation. The zero-flow initialization means
there is no separate feasibility problem.

The algorithm idea follows Andrew V. Goldberg and Robert E. Tarjan,
[“Finding Minimum-Cost Circulations by Successive Approximation”](https://doi.org/10.1287/moor.15.3.430),
*Mathematics of Operations Research* 15(3), 1990. The detailed generic
refinement is also described in Goldberg's [network-flow technical
report](https://www.cs.princeton.edu/techreports/1989/216.pdf). Only algorithm
ideas were consulted; the contract, workload, oracles, and ports are
independently authored.

| Language | Port |
|---|---|
| C | [c/m/minimum_cost_circulation_cost_scaling.c](../../../c/m/minimum_cost_circulation_cost_scaling.c) |
| C3 | [c3/m/minimum_cost_circulation_cost_scaling.c3](../../../c3/m/minimum_cost_circulation_cost_scaling.c3) |
| C++ | [cpp/m/minimum_cost_circulation_cost_scaling.cpp](../../../cpp/m/minimum_cost_circulation_cost_scaling.cpp) |
| Elisa | [elisa/m/minimum_cost_circulation_cost_scaling.elisa](../../../elisa/m/minimum_cost_circulation_cost_scaling.elisa) |
| Mojo | [mojo/m/minimum_cost_circulation_cost_scaling.mojo](../../../mojo/m/minimum_cost_circulation_cost_scaling.mojo) |
| Nim | [nim/m/minimum_cost_circulation_cost_scaling.nim](../../../nim/m/minimum_cost_circulation_cost_scaling.nim) |
| Odin | [odin/m/minimum_cost_circulation_cost_scaling.odin](../../../odin/m/minimum_cost_circulation_cost_scaling.odin) |
| Rust | [rust/m/minimum_cost_circulation_cost_scaling.rs](../../../rust/m/minimum_cost_circulation_cost_scaling.rs) |
| V | [v/m/minimum_cost_circulation_cost_scaling.v](../../../v/m/minimum_cost_circulation_cost_scaling.v) |
| Zig | [zig/m/minimum_cost_circulation_cost_scaling.zig](../../../zig/m/minimum_cost_circulation_cost_scaling.zig) |
