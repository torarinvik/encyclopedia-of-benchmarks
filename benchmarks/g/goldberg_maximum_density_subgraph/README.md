# Goldberg exact maximum-density subgraph

This package profiles the exact maximum-density induced-subgraph algorithm in
A. V. Goldberg's 1984 report. Its objective is
`max |E[S]| / |S|` over all nonempty vertex subsets `S`. It is separate from
the local Charikar shell-order, BKV12 threshold-peeling, and GreedyPlusPlus
profiles, which return approximations using peeling procedures.

## Contract

- Exported symbol: `goldberg_maximum_density_subgraph`; ABI: `i64_array_scalar`.
- Input: `[N, M, (u, v)*M]`; `2 <= N <= 8`, `0 <= M <= 28`.
- Each edge is a simple undirected edge exactly once, with `0 <= u < v < N`.
  Edge order is unrestricted. Disconnected graphs and isolates are valid.
- The frame length is exactly `2 + 2*M`; malformed input returns `-1`.
- The output is `p*(N+1)+q`, where `p/q` is the reduced exact maximum
  density. An edgeless graph returns `1`, encoding `0/1`. The safe output
  bound is `28*(8+1)+8 = 260`.
- Maximum valid and parseable lengths are 58 and 59 signed 64-bit words.

## Algorithm

The primary and ten ports use Goldberg's binary search over `g` in `[0,M]`.
For each dyadic midpoint `g=a/d`, they build the report's `N+2` vertex
network, scaled by `d`: source-to-vertex capacity `M*d`, both directed arcs
for each undirected input edge with capacity `d`, and vertex-to-sink capacity
`M*d + 2*a - d*degree(v)`. These capacities are nonnegative. A deterministic
minimum cut is computed by Edmonds–Karp. If the residual source side contains
an input vertex, that induced subset is saved and the lower bound advances;
otherwise the upper bound retreats. The search stops once the interval is
strictly smaller than `1/(N*(N-1))`. Distinct possible densities `e/s` with
`1 <= s <= N` are separated by at least that amount, so the saved subset is
optimal. The final reduced ratio is computed from its vertex and induced-edge
counts. Ties in minimum cuts use the residual-reachable source side.

The primary Python oracle follows this min-cut search. The independent oracle
enumerates every nonempty vertex subset and compares ratios by integer cross
multiplication. The workload includes manual cases for empty, sparse, dense,
disconnected, malformed, and maximum-size frames.

## Source and rights

Primary source: A. V. Goldberg, [Finding a Maximum Density
Subgraph](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1984/Archive/CSD-84-171.pdf),
UC Berkeley technical report CSD-84-171 (1984), especially Sections 2–4.
The report is used as an algorithm reference only; no source code or prose is
reproduced. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

[C](../../../c/g/goldberg_maximum_density_subgraph.c) ·
[C3](../../../c3/g/goldberg_maximum_density_subgraph.c3) ·
[C++](../../../cpp/g/goldberg_maximum_density_subgraph.cpp) ·
[Elisa](../../../elisa/g/goldberg_maximum_density_subgraph.elisa) ·
[Mojo](../../../mojo/g/goldberg_maximum_density_subgraph.mojo) ·
[Nim](../../../nim/g/goldberg_maximum_density_subgraph.nim) ·
[Odin](../../../odin/g/goldberg_maximum_density_subgraph.odin) ·
[Rust](../../../rust/g/goldberg_maximum_density_subgraph.rs) ·
[V](../../../v/g/goldberg_maximum_density_subgraph.v) ·
[Zig](../../../zig/g/goldberg_maximum_density_subgraph.zig)

The workload and independent reference are [`workload.json`](workload.json),
[`primary_oracle.py`](primary_oracle.py), and
[`independent_oracle.py`](independent_oracle.py). The package-local inventory
reviewer is [`verify_workload.py`](verify_workload.py).
