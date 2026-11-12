# Minimum-cost b-flow

Find a minimum-cost integral flow that satisfies a supplied net-outflow value
at every vertex and lower/upper flow bounds on every directed edge. The
bounded ports start at every lower bound, use Edmonds–Karp to find a feasible
adjustment, cancel negative residual cycles until no cheaper circulation
remains, then derive dual potentials from residual shortest paths. This also
handles negative costs and negative lower bounds.

## Contract

Input is `[n, m, (b_v)[n], (u, v, lower, upper, cost)[m]]`. Vertices are
zero-based; `0 <= n <= 8`, `0 <= m <= 10`, `|b_v| <= 5`, `-3 <= lower <= upper
<= 3`, `upper-lower <= 2`, and `|cost| <= 4`. Self-loops and parallel edges
are allowed. Exact input length is `2+n+5*m` words. A feasible flow must obey
`outflow(v)-inflow(v)=b_v` at every vertex.

Output is little-endian signed i64 words `[status, cost, p_0, ..., p_(n-1),
f_0, ..., f_(m-1)]`, occupying `8*(2+n+m)` bytes. `status=1` means the remaining
words give a minimum-cost flow and a dual-potential certificate; `status=0`
means infeasible, with every remaining word zero. For each edge, the returned
potential must satisfy the task's complementary-slackness inequalities:
`f>lower => cost+p_from-p_to <= 0`, and `f<upper => cost+p_from-p_to >= 0`.
Every potential is within the official `10^15` bound. Invalid input returns
`-1`; a null or undersized output buffer returns `-2` without writes.

The local [`min_cost_max_flow`](../min_cost_max_flow/README.md) package follows
AtCoder's source/sink, zero-lower-bound contract, caps initial costs at
nonnegative values, and stops at a flow limit. This package accepts a balance
at every vertex, signed lower and upper bounds, negative costs, and profitable
circulations, and returns per-edge flows and dual potentials. It is a distinct
general b-flow operation.

This is a clean-room bounded profile of [Library Checker Minimum Cost
b-flow](https://judge.yosupo.jp/problem/min_cost_b_flow). The official task
allows `n<=100`, `m<=1000`, and magnitudes up to `10^9`; the package narrows
these bounds while preserving negative cycles, lower bounds, feasibility, and
the primal/dual certificate. The independent oracle finds canonical output
with a separate residual implementation and checks certificates through
primal feasibility and complementary slackness. It enumerates bounded flow
assignments when checking infeasibility. See [`workload.json`](workload.json)
and [`benchmarks/minimum_cost_b_flow_oracle.py`](../../minimum_cost_b_flow_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/minimum_cost_b_flow.c`](../../../c/m/minimum_cost_b_flow.c) |
| C3 | [`c3/m/minimum_cost_b_flow.c3`](../../../c3/m/minimum_cost_b_flow.c3) |
| C++ | [`cpp/m/minimum_cost_b_flow.cpp`](../../../cpp/m/minimum_cost_b_flow.cpp) |
| Elisa | [`elisa/m/minimum_cost_b_flow.elisa`](../../../elisa/m/minimum_cost_b_flow.elisa) |
| Mojo | [`mojo/m/minimum_cost_b_flow.mojo`](../../../mojo/m/minimum_cost_b_flow.mojo) |
| Nim | [`nim/m/minimum_cost_b_flow.nim`](../../../nim/m/minimum_cost_b_flow.nim) |
| Odin | [`odin/m/minimum_cost_b_flow.odin`](../../../odin/m/minimum_cost_b_flow.odin) |
| Rust | [`rust/m/minimum_cost_b_flow.rs`](../../../rust/m/minimum_cost_b_flow.rs) |
| V | [`v/m/minimum_cost_b_flow.v`](../../../v/m/minimum_cost_b_flow.v) |
| Zig | [`zig/m/minimum_cost_b_flow.zig`](../../../zig/m/minimum_cost_b_flow.zig) |
