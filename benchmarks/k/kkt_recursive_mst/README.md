# Karger–Klein–Tarjan recursive minimum spanning forest

This bounded profile implements the complete Karger–Klein–Tarjan (KKT)
recursive minimum-spanning-forest algorithm. Each recursive call first takes
two Borůvka steps and contracts their selected edges, samples the remaining
edges, recursively computes a minimum spanning forest of the sample, removes
edges that are heavy with respect to that forest, and recursively processes
the surviving graph.

The local [`kkt_mst_sampling_filter`](../kkt_mst_sampling_filter/README.md)
benchmark covers only one sampled-forest classification stage. It does not
perform Borůvka contraction or the two KKT recursive calls, so the full
algorithm is distinct.

## Contract

The `i64_array_scalar` input is `[n,m,seed,(u,v,weight)*m]`. It permits
`1 <= n <= 16`, `0 <= m <= 16`, `0 <= seed <= INT64_MAX`, and integer weights
from 0 through 255. Edges must be canonical (`0 <= u < v < n`) and no
undirected pair may repeat. Disconnected graphs and isolated vertices are
valid. The exact frame length is `3 + 3*m`; maximum valid and parseable lengths
are 51 and 52 values. Null, malformed, or out-of-range input returns `-1`.

The algorithm totally orders edges by `(weight, original_input_edge_id)`,
which makes the minimum spanning forest unique even when weights tie. The
result is a bitmask: bit `i` is set exactly when original input edge `i` is in
that forest. The mask fits in a nonnegative signed 64-bit result.

Sampling uses a reproducible SplitMix64 stream initialized from `seed`; one
low output bit is consumed per surviving contracted edge, in total-key order,
at each sampling step. The same mutable stream continues through recursive
calls. This makes the benchmark repeatable while preserving the KKT algorithm's
sampled recursive structure. It does not claim the paper's asymptotic running
time on these bounded, straightforward implementations.

After each Borůvka phase, the ports contract selected components, discard
loops, and keep only the lightest edge for each parallel component pair. To
classify F-heavy edges, they find paths in the recursively returned forest and
compare the edge's total key with the maximum total key on that path. An edge
whose endpoints are disconnected in the sample forest remains F-light.

| Language | Port |
|---|---|
| C | [c/k/kkt_recursive_mst.c](../../../c/k/kkt_recursive_mst.c) |
| C3 | [c3/k/kkt_recursive_mst.c3](../../../c3/k/kkt_recursive_mst.c3) |
| C++ | [cpp/k/kkt_recursive_mst.cpp](../../../cpp/k/kkt_recursive_mst.cpp) |
| Elisa | [elisa/k/kkt_recursive_mst.elisa](../../../elisa/k/kkt_recursive_mst.elisa) |
| Mojo | [mojo/k/kkt_recursive_mst.mojo](../../../mojo/k/kkt_recursive_mst.mojo) |
| Nim | [nim/k/kkt_recursive_mst.nim](../../../nim/k/kkt_recursive_mst.nim) |
| Odin | [odin/k/kkt_recursive_mst.odin](../../../odin/k/kkt_recursive_mst.odin) |
| Rust | [rust/k/kkt_recursive_mst.rs](../../../rust/k/kkt_recursive_mst.rs) |
| V | [v/k/kkt_recursive_mst.v](../../../v/k/kkt_recursive_mst.v) |
| Zig | [zig/k/kkt_recursive_mst.zig](../../../zig/k/kkt_recursive_mst.zig) |

The implementation follows Karger, Klein, and Tarjan's [randomized linear-time
minimum spanning tree algorithm](https://doi.org/10.1145/201019.201022) (1995).
Only the algorithmic ideas are used; code, examples, and prose are independently
authored.
