# Lower-bound circulation feasibility

This profile decides whether a directed multigraph admits an integral
circulation whose edge flow stays between each supplied lower and upper bound.
For each edge `(u,v,l,h)`, the implementation reserves residual capacity
`h-l`, subtracts `l` from `u`'s balance, and adds `l` to `v`'s balance. It
then connects a super-source to positive-balance vertices and negative-balance
vertices to a super-sink. The circulation is feasible exactly when a maximum
flow saturates all super-source arcs. The ports use Edmonds–Karp for this
bounded profile. This is a feasibility transformation, not a minimum-cost
circulation benchmark.

## Contract

The `i64_array_scalar` input is `[n,m,(u,v,lower,upper)*m]`. It requires
`1<=n<=6`, `0<=m<=8`, zero-based endpoints in `[0,n)`, and
`0<=lower<=upper<=2`. Parallel arcs and self-loops are allowed. The exact
frame length is `2+4*m`; the maximum valid frame has 34 signed 64-bit words,
and the maximum parseable frame has 35 words so a trailing-word error is
rejected. Null, short, long, malformed, or out-of-domain inputs return `-1`.
For valid input the result is `1` when a feasible integral circulation exists
and `0` otherwise. The result does not expose a particular flow, so residual
path tie choices cannot change the output.

The largest input admits at most `3^8=6,561` assignments in the independent
oracle. That oracle enumerates edge flows and checks conservation directly;
the primary reference and language ports use the super-source reduction.
All internal vertex, edge, residual-capacity, and queue storage is fixed and
bounded; the package reserves 1,024 bytes of workspace. Scalar workload cases
set per-call external workspace to zero.

At most `m+n=14` forward arcs enter the transformed network: each nonzero
balance contributes one super-source or super-sink arc, and there are at most
`n` such vertices. The residual matrix represents at most 28 directed
residual directions. Each matrix-based BFS scans at most `8*8=64` cells;
Edmonds–Karp therefore takes `O(V^3 E)` time with `V<=8` and `E<=14` for this
implementation.

The algorithm description follows the CP-Algorithms
[Flow with demands](https://cp-algorithms.com/graph/flow_with_demands.html)
article, which presents the lower/upper-bound reduction to maximum flow. The
article is licensed CC BY-SA 4.0. Only the algorithm idea was consulted; all
contract details, workload data, references, and ports are original to this
benchmark package.

| Language | Port |
|---|---|
| C | [c/l/lower_bound_circulation_feasibility.c](../../../c/l/lower_bound_circulation_feasibility.c) |
| C3 | [c3/l/lower_bound_circulation_feasibility.c3](../../../c3/l/lower_bound_circulation_feasibility.c3) |
| C++ | [cpp/l/lower_bound_circulation_feasibility.cpp](../../../cpp/l/lower_bound_circulation_feasibility.cpp) |
| Elisa | [elisa/l/lower_bound_circulation_feasibility.elisa](../../../elisa/l/lower_bound_circulation_feasibility.elisa) |
| Mojo | [mojo/l/lower_bound_circulation_feasibility.mojo](../../../mojo/l/lower_bound_circulation_feasibility.mojo) |
| Nim | [nim/l/lower_bound_circulation_feasibility.nim](../../../nim/l/lower_bound_circulation_feasibility.nim) |
| Odin | [odin/l/lower_bound_circulation_feasibility.odin](../../../odin/l/lower_bound_circulation_feasibility.odin) |
| Rust | [rust/l/lower_bound_circulation_feasibility.rs](../../../rust/l/lower_bound_circulation_feasibility.rs) |
| V | [v/l/lower_bound_circulation_feasibility.v](../../../v/l/lower_bound_circulation_feasibility.v) |
| Zig | [zig/l/lower_bound_circulation_feasibility.zig](../../../zig/l/lower_bound_circulation_feasibility.zig) |
