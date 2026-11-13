# General weighted matching

This package returns a maximum-total-weight matching of a simple undirected
graph. The bounded implementation uses exact bitmask dynamic programming. For
each available-vertex mask it selects the smallest vertex and either leaves it
unmatched or pairs it with one available neighbor. Edge weights are positive,
so the objective is maximum total weight rather than maximum cardinality.

The recurrence takes `O(N 2^N)` time and `O(2^N + N^2)` storage. Reconstruction
uses the same table to emit a deterministic certificate: unmatched is preferred
on equal weight, then available partners are considered in ascending vertex
order. Every emitted pair is normalized as `u < v`, and pairs appear in
ascending order of their first endpoint.

## Contract

Input is a signed 64-bit array `[N,M,u0,v0,w0,...]`, with one triple per
undirected edge. The graph must be simple: self-loops and repeated edges are
invalid, even when a duplicate is listed in reverse endpoint order. Edge
endpoint order in each triple is otherwise arbitrary. The local profile uses
`1 <= N <= 16`, `0 <= M <= N(N-1)/2`, and `1 <= w <= 1,000,000`. A valid
complete graph at the maximum size uses 362 words; one additional word is
accepted only so trailing input can be rejected cleanly.

The output is a compact little-endian signed 64-bit word vector
`[matching_size,total_weight,u0,v0,...]`. Matching pairs use normalized
endpoints. The byte count is the result value. The maximum certificate has 18
words, or 144 bytes. Invalid input returns `-1`; a null or undersized output
buffer returns `-2` without writing bytes. The `workspace.bytes` field records
the output-buffer capacity. The DP table and graph storage are separate bounded
memory.

The official task permits `N <= 500`, as many as `N(N-1)/2` edges, and edge
weights in `[1,1,000,000]`. This benchmark deliberately uses a smaller exact
DP profile and does not claim the weighted blossom algorithm's large-graph
asymptotic performance.

## Distinctness

[`edmonds_blossom_algorithm`](../../e/edmonds_blossom_algorithm/README.md)
optimize matching cardinality in an unweighted general graph. Weighted stable
and popular matching packages optimize preference-based objectives, and
[`tree_matching`](../../t/tree_matching/README.md) relies on a tree structure.
They do not solve maximum total edge weight in an arbitrary simple graph.

Official contract: [Library Checker — General Weighted Matching](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/general_weighted_matching/task.md)
and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/general_weighted_matching/info.toml).
The language ports and local oracles are clean-room implementations of the
bounded subset-DP profile.

## Workload and oracles

[`workload.json`](workload.json) covers empty graphs, a singleton, odd cycles,
weight/cardinality tradeoffs, deterministic ties, malformed simple-graph
inputs, trailing words, null output, and insufficient capacity. The primary
[`benchmarks/general_weighted_matching_oracle.py`](../../general_weighted_matching_oracle.py)
uses a bottom-up bitmask table. The independent
[`benchmarks/general_weighted_matching_checker.py`](../../general_weighted_matching_checker.py)
uses memoized recursive enumeration of unmatched and paired choices. The
package-local [`verify_general_weighted_matching_package.py`](../../verify_general_weighted_matching_package.py)
statically checks metadata, source inventory, and fixture agreement.

## Implementations

| Language | Source |
|---|---|
| C | [`c/g/general_weighted_matching.c`](../../../c/g/general_weighted_matching.c) |
| C3 | [`c3/g/general_weighted_matching.c3`](../../../c3/g/general_weighted_matching.c3) |
| C++ | [`cpp/g/general_weighted_matching.cpp`](../../../cpp/g/general_weighted_matching.cpp) |
| Elisa | [`elisa/g/general_weighted_matching.elisa`](../../../elisa/g/general_weighted_matching.elisa) |
| Mojo | [`mojo/g/general_weighted_matching.mojo`](../../../mojo/g/general_weighted_matching.mojo) |
| Nim | [`nim/g/general_weighted_matching.nim`](../../../nim/g/general_weighted_matching.nim) |
| Odin | [`odin/g/general_weighted_matching.odin`](../../../odin/g/general_weighted_matching.odin) |
| Rust | [`rust/g/general_weighted_matching.rs`](../../../rust/g/general_weighted_matching.rs) |
| V | [`v/g/general_weighted_matching.v`](../../../v/g/general_weighted_matching.v) |
| Zig | [`zig/g/general_weighted_matching.zig`](../../../zig/g/general_weighted_matching.zig) |
