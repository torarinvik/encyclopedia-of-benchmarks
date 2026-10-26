# Bottom-k all-distances sketch

This package constructs one deterministic bottom-k all-distances sketch (ADS)
for a selected source vertex. It uses a supplied permutation of vertex ranks
as the random-permutation realization. Directed edges have unit cost; BFS
distances are ordered by `(distance, vertex_id)` to resolve equal-distance
ties. For each reachable vertex `u`, retain it exactly when its rank is among
the `k` smallest ranks in the source's ordered distance prefix ending at `u`.
The output lists retained `(vertex_id, distance)` pairs in that order.

## Contract

ABI: `i64_array_bytes_output`; symbol: `all_distances_sketch_bottom_k`.
Input is `[n,m,k,source,rank[n],edge_pairs[2*m]]`; ranks must be a permutation
of `0..n-1`. The graph is directed and simple, with no self-loops. Bounds are
`2<=n<=10`, `0<=m<=n(n-1)`, `1<=k<=n`, and source in `0..n-1`. The maximum
input is 104 signed 64-bit words. Output is `[count,(id,distance)[count]]`,
little-endian signed 64-bit words, with at most 21 words / 168 bytes.
Malformed input returns `-1` before output checks; null output or insufficient
capacity returns `-2` without writes. Unreachable vertices are absent.

This is one explicit bottom-k ADS realization, not a randomized accuracy
experiment and not a full collection of sketches for every vertex. The rank
permutation is part of the input so the behavior is reproducible.

## Source and rights

Based on Edith Cohen, “All-Distances Sketches,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_574`](https://doi.org/10.1007/978-1-4939-2864-4_574),
specifically the bottom-k ADS definition. The ports are independent
implementations and include no copied book text or code; see [`RIGHTS.md`](RIGHTS.md).

Fixtures are in [`workload.json`](workload.json). The primary oracle is
[`all_distances_sketch_bottom_k_oracle.py`](../../all_distances_sketch_bottom_k_oracle.py);
the independent verifier is
[`all_distances_sketch_bottom_k_verifier_oracle.py`](../../all_distances_sketch_bottom_k_verifier_oracle.py).

Language ports: `c/a/all_distances_sketch_bottom_k.c`,
`c3/a/all_distances_sketch_bottom_k.c3`,
`cpp/a/all_distances_sketch_bottom_k.cpp`,
`elisa/a/all_distances_sketch_bottom_k.elisa`,
`nim/a/all_distances_sketch_bottom_k.nim`,
`odin/a/all_distances_sketch_bottom_k.odin`,
`rust/a/all_distances_sketch_bottom_k.rs`,
`v/a/all_distances_sketch_bottom_k.v`, and
`zig/a/all_distances_sketch_bottom_k.zig`.
