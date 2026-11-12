# Global min-cut after dynamic star-edge updates

This package implements the update workload in Library Checker
`global_minimum_cut_of_dynamic_star_augmented_graph`. The input is a weighted
simple undirected graph on `N` vertices, augmented with a new supernode and one
spoke edge per original vertex. Each query replaces one spoke weight and asks
for the augmented graph's global min-cut.

The bounded profile uses `1<=N<=16`, `M<=64`, `1<=Q<=32`, and weights up to
1,000,000. It applies each replacement and recomputes the current global
minimum cut with Stoer-Wagner. Phase selection takes the active vertex with
maximum accumulated adjacency weight, breaking ties by lowest vertex ID. This
is a small-graph recomputation profile and does not claim the official
dynamic-scale performance. The independent verifier enumerates all cuts by
choosing the non-supernode side.

## ABI

Symbol: `global_minimum_cut_of_dynamic_star_augmented_graph`, ABI
`i64_array_bytes_output`. Input is
`[N,M,Q,spoke_weights[N],edges[3*M],updates[2*Q]]`; vertices are zero-based.
The original graph must be simple, with no self-loops or duplicate undirected
edges. Each update is `[vertex,new_weight]`. Malformed input returns `-1`
before output checks. Valid input with null output or capacity below `8*Q`
returns `-2` without writes. Success writes `Q` little-endian signed 64-bit
min-cut values. Maximum valid input length is 275 words, parseable limit 276,
and output maximum 256 bytes.

## Source and rights

The operation and official parameter context come from the Apache-2.0
licensed Library Checker repository: [task](https://github.com/yosupo06/library-checker-problems/blob/master/graph/global_minimum_cut_of_dynamic_star_augmented_graph/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/global_minimum_cut_of_dynamic_star_augmented_graph/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The bounded implementations are clean-room. See [RIGHTS.md](RIGHTS.md).

Workload: [workload.json](workload.json). Primary oracle:
[`global_minimum_cut_of_dynamic_star_augmented_graph_oracle.py`](../../global_minimum_cut_of_dynamic_star_augmented_graph_oracle.py);
independent checker oracle:
[`global_minimum_cut_of_dynamic_star_augmented_graph_verifier_oracle.py`](../../global_minimum_cut_of_dynamic_star_augmented_graph_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/g/global_minimum_cut_of_dynamic_star_augmented_graph.c`](../../../c/g/global_minimum_cut_of_dynamic_star_augmented_graph.c) |
| C3 | [`c3/g/global_minimum_cut_of_dynamic_star_augmented_graph.c3`](../../../c3/g/global_minimum_cut_of_dynamic_star_augmented_graph.c3) |
| C++ | [`cpp/g/global_minimum_cut_of_dynamic_star_augmented_graph.cpp`](../../../cpp/g/global_minimum_cut_of_dynamic_star_augmented_graph.cpp) |
| Elisa | [`elisa/g/global_minimum_cut_of_dynamic_star_augmented_graph.elisa`](../../../elisa/g/global_minimum_cut_of_dynamic_star_augmented_graph.elisa) |
| Mojo | [`mojo/g/global_minimum_cut_of_dynamic_star_augmented_graph.mojo`](../../../mojo/g/global_minimum_cut_of_dynamic_star_augmented_graph.mojo) |
| Nim | [`nim/g/global_minimum_cut_of_dynamic_star_augmented_graph.nim`](../../../nim/g/global_minimum_cut_of_dynamic_star_augmented_graph.nim) |
| Odin | [`odin/g/global_minimum_cut_of_dynamic_star_augmented_graph.odin`](../../../odin/g/global_minimum_cut_of_dynamic_star_augmented_graph.odin) |
| Rust | [`rust/g/global_minimum_cut_of_dynamic_star_augmented_graph.rs`](../../../rust/g/global_minimum_cut_of_dynamic_star_augmented_graph.rs) |
| V | [`v/g/global_minimum_cut_of_dynamic_star_augmented_graph.v`](../../../v/g/global_minimum_cut_of_dynamic_star_augmented_graph.v) |
| Zig | [`zig/g/global_minimum_cut_of_dynamic_star_augmented_graph.zig`](../../../zig/g/global_minimum_cut_of_dynamic_star_augmented_graph.zig) |
