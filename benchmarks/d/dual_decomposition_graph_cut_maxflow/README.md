# Dual-decomposition graph-cut maxflow

This package benchmarks a bounded two-subproblem dual-decomposition method
for an exact graph cut. Each subproblem contains one exclusive vertex set and
the shared overlap; dual variables encourage the two independently optimal
overlap labels to agree. The profile evaluates M then N serially in one call;
it measures the dual optimization work without starting parallel workers.

## Contract

- ABI: `i64_array_scalar`, symbol `dual_decomposition_graph_cut_maxflow`.
- Input: `[N,M,O,T,owner[N],source_caps[N],sink_caps[N],(u,v,cap_uv,cap_vu)*M]`.
- `3<=N<=6`, `0<=M<=10`, overlap count `1<=O<=3`, and round cap `1<=T<=8`.
- Owner code `0` means M-only, `1` means N-only, and `2` means shared. Both
  exclusive sides must contain a vertex. Edges between M-only and N-only
  vertices are invalid; all other endpoint pairs are assigned to their
  containing subproblem(s).
- Terminal and directed arc capacities must be even integers in `0..6`.
  Shared terminal arcs and shared-to-shared arcs are included in both
  subproblems at half capacity. Parallel arcs are summed; self-loops are
  invalid.
- Valid input length is exactly `4+3N+4M`; maximum valid and parseable lengths
  are 62 and 63 words. Invalid or null input returns `-1`.

## Fixed finite-iteration profile

The multiplier vector starts at zero. At each 1-based iteration `k`, both
subproblems are solved exactly. M adds `lambda*x` and N adds `-lambda*y` for
each shared vertex's sink-side label bit. Unless all shared labels agree or
the requested final round has been evaluated, the update is
`lambda += (x-y)/k`. This selects the paper's Section 3 `tau=1/k` ascent rule;
the profile does not implement the authors' later empirical per-vertex step
adaptation from Section 4.

Every capacity is even, so duplicated overlap costs can be halved without
rounding. Let `D=lcm(2,1,...,T)`. All graph capacities are multiplied by `D`,
and `D*lambda` is stored as an integer; every `D/k` update and shared half-cost
is exact. In particular, `T=1` still uses `D=2`, so shared half-capacity terms
remain integral even when there are no multiplier updates. Each subproblem
chooses its maximal sink-side min-cut, setting a label to 1 wherever that
remains optimal.

The scalar output is
`2*(g_scaled+7000)+agreement`, where `g_scaled=D*g(lambda)` for
`D=lcm(2,1,...,T)`, and the low bit is
the agreement flag. Decode the dual lower bound as
`(output//2-7000)/D`. If the flag is 1, the overlap labels agree and this value
is the exact global min-cut/maxflow by strong duality. If it is 0, the value is
only a lower bound; the profile never presents disagreement as an exact cut.
At most seven updates occur, so each scaled multiplier has magnitude at most
`840*H_7=2178`; with three overlap vertices the dual is bounded below by
`-6534`. The all-sink labeling cancels all dual terms and costs at most the
sum of source capacities, at most 36, so weak duality bounds the scaled dual
above by `36*840=30240`. The 7000 offset keeps the packed value nonnegative,
and the maximum packed result is `2*(30240+7000)+1=74481`.

This method differs from LIUSUN and PEIBFS: they split disjoint blocks, then
restore graph boundaries and merge residual maxflow state; this profile keeps
overlapping subproblems separate and coordinates their labels with Lagrange
multipliers. It also differs from region discharge, which schedules residual
flow operations between regions rather than optimizing a dual objective.

## Provenance and rights

Strandmark and Kahl, [“Parallel and Distributed Graph Cuts by Dual
Decomposition”](https://doi.org/10.1109/CVPR.2010.5539886), describe the
overlap-label formulation, supergradient update, maximal-label tie rule, and
even-cost integer-multiplier result. The implementation here is a clean-room
bounded profile of their Section 3 method; it does not reproduce their
Section 4 step adaptation, distributed runtime, BK tree reuse, or empirical
benchmark instances. See [RIGHTS](RIGHTS.md).

The fixture set is in [workload.json](workload.json). The primary residual-flow
reference is [primary_oracle.py](primary_oracle.py); the independent reference
enumerates cuts directly in [independent_oracle.py](independent_oracle.py).
The callable static inventory is [verify_workload.py](verify_workload.py).

| Language | Port |
|---|---|
| C | [c/d/dual_decomposition_graph_cut_maxflow.c](../../../c/d/dual_decomposition_graph_cut_maxflow.c) |
| C3 | [c3/d/dual_decomposition_graph_cut_maxflow.c3](../../../c3/d/dual_decomposition_graph_cut_maxflow.c3) |
| C++ | [cpp/d/dual_decomposition_graph_cut_maxflow.cpp](../../../cpp/d/dual_decomposition_graph_cut_maxflow.cpp) |
| Elisa | [elisa/d/dual_decomposition_graph_cut_maxflow.elisa](../../../elisa/d/dual_decomposition_graph_cut_maxflow.elisa) |
| Mojo | [mojo/d/dual_decomposition_graph_cut_maxflow.mojo](../../../mojo/d/dual_decomposition_graph_cut_maxflow.mojo) |
| Nim | [nim/d/dual_decomposition_graph_cut_maxflow.nim](../../../nim/d/dual_decomposition_graph_cut_maxflow.nim) |
| Odin | [odin/d/dual_decomposition_graph_cut_maxflow.odin](../../../odin/d/dual_decomposition_graph_cut_maxflow.odin) |
| Rust | [rust/d/dual_decomposition_graph_cut_maxflow.rs](../../../rust/d/dual_decomposition_graph_cut_maxflow.rs) |
| V | [v/d/dual_decomposition_graph_cut_maxflow.v](../../../v/d/dual_decomposition_graph_cut_maxflow.v) |
| Zig | [zig/d/dual_decomposition_graph_cut_maxflow.zig](../../../zig/d/dual_decomposition_graph_cut_maxflow.zig) |
