# Howard minimum mean cycle

Return the exact minimum average edge weight among directed cycles in a
bounded strongly connected graph. The primary implementation is Howard's
policy-iteration method: it evaluates a functional graph of selected outgoing
edges, then improves the policy by lexicographically comparing each edge's
cycle mean and adjusted potential. This is distinct from the local
[`minimum_mean_cycle_karp`](../minimum_mean_cycle_karp/README.md), which uses
exact-length walk dynamic programming and Karp's min-max characterization.

## Contract

Input is `[n,m,(u,v,weight)*m]`, with `1<=n<=8`,
`1<=m<=min(16,n*n)`, zero-based endpoints, and weights in `[-1000,1000]`.
The graph must be strongly connected and have unique ordered endpoint pairs;
self-loops are allowed. The exact input length is `2+3*m`. Invalid input
returns `-1` before output checks.

Output is two signed little-endian i64 words:
`[reduced_numerator, positive_denominator]`. The function returns 16 bytes;
null output or capacity below 16 returns `-2` without writing. Workspace is
2,048 bytes.

Each policy chooses one outgoing edge per vertex. Its directed functional
graph consists of cycles with in-trees. Policy evaluation assigns each vertex
the exact mean of its eventual cycle and a bias satisfying
`bias[u] = weight(u,policy[u]) - mean[u] + bias[policy[u]]`; a deterministic
minimum-ID cycle vertex anchors each bias at zero. For each outgoing edge
`u->v`, Howard's improvement step compares
`(mean[v], weight(u,v)-mean[v]+bias[v])` lexicographically and switches only
to a strictly smaller appraisal. Exact rational comparisons avoid floating
point. Every iteration costs `O(n+m)`; the number of possible policies is
bounded by the product of outdegrees, at most 324 for this workload.

The independent oracle enumerates simple cycles once each from their least
vertex and compares exact rational means. It uses a different search structure
from policy iteration. The workload reuses the bounded Karp graph domain for
direct method comparisons and includes fractional, negative, zero, and
malformed cases.

Algorithm description and analysis follow Thomas Dueholm Hansen and Uri
Zwick, [“Lower Bounds for Howard's Algorithm for Finding Minimum Mean-Cost
Cycles”](https://doi.org/10.1007/978-3-642-17517-6_37). The current iteration
bound for this minimum-mean-cycle policy variant is not known to be
polynomial; the small contract bounds the number of policies. Only algorithm
ideas were consulted.

| Language | Port |
|---|---|
| C | [c/m/minimum_mean_cycle_howard.c](../../../c/m/minimum_mean_cycle_howard.c) |
| C3 | [c3/m/minimum_mean_cycle_howard.c3](../../../c3/m/minimum_mean_cycle_howard.c3) |
| C++ | [cpp/m/minimum_mean_cycle_howard.cpp](../../../cpp/m/minimum_mean_cycle_howard.cpp) |
| Elisa | [elisa/m/minimum_mean_cycle_howard.elisa](../../../elisa/m/minimum_mean_cycle_howard.elisa) |
| Mojo | [mojo/m/minimum_mean_cycle_howard.mojo](../../../mojo/m/minimum_mean_cycle_howard.mojo) |
| Nim | [nim/m/minimum_mean_cycle_howard.nim](../../../nim/m/minimum_mean_cycle_howard.nim) |
| Odin | [odin/m/minimum_mean_cycle_howard.odin](../../../odin/m/minimum_mean_cycle_howard.odin) |
| Rust | [rust/m/minimum_mean_cycle_howard.rs](../../../rust/m/minimum_mean_cycle_howard.rs) |
| V | [v/m/minimum_mean_cycle_howard.v](../../../v/m/minimum_mean_cycle_howard.v) |
| Zig | [zig/m/minimum_mean_cycle_howard.zig](../../../zig/m/minimum_mean_cycle_howard.zig) |
