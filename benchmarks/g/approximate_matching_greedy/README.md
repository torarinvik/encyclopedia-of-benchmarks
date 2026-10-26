# Greedy approximate maximum-weight matching

This package implements the chapter’s simple 1/2-approximation for maximum
weight matching: repeatedly select the maximum-weight edge whose endpoints
remain unmatched. The implementation processes all edges in descending
weight order; equal weights use the original input edge index as a
deterministic tie-break. For positive weights, the result is a maximal
matching and has at least half the optimum total weight.

## Contract

ABI: `i64_array_bytes_output`, exported symbol `approximate_matching_greedy`.
Input is `[vertex_count,edge_count,(u,v,weight)...]`, with 1–12 vertices and
0–32 simple undirected edges. Endpoints may be given in either order, but
self-loops and repeated unordered pairs are invalid. Weights are integers in
1..100. The output is two little-endian signed 64-bit words:
`[matching_total_weight,selected_edge_mask]`; bit `i` identifies whether edge
`i` from the input was selected. Invalid input returns `-1`; null or short
output returns `-2` without writing. Input is at most 98 words; output is 16
bytes.

This differs from [`gbbs_maximal_matching`](../gbbs_maximal_matching/README.md),
which follows a supplied edge-priority order to obtain a maximal matching
without weights or a maximum-weight approximation guarantee. It also differs
from exact maximum-cardinality matching profiles.

## Source attribution and rights

Based on Ran Duan, “Approximate Matching,” *Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_570](https://doi.org/10.1007/978-1-4939-2864-4_570).
The ports independently implement the chapter-described greedy edge rule;
no book code, prose, or figures are reproduced. Springer retains copyright
to the book; attribution does not grant redistribution rights to its
contents.

The primary oracle is
[`approximate_matching_greedy_oracle.py`](../../approximate_matching_greedy_oracle.py);
the independent verifier is
[`approximate_matching_greedy_verifier_oracle.py`](../../approximate_matching_greedy_verifier_oracle.py).

| Language | Source |
|---|---|
| C | [`c/g/approximate_matching_greedy.c`](../../../c/g/approximate_matching_greedy.c) |
| C3 | [`c3/g/approximate_matching_greedy.c3`](../../../c3/g/approximate_matching_greedy.c3) |
| C++ | [`cpp/g/approximate_matching_greedy.cpp`](../../../cpp/g/approximate_matching_greedy.cpp) |
| Elisa | [`elisa/g/approximate_matching_greedy.elisa`](../../../elisa/g/approximate_matching_greedy.elisa) |
| Nim | [`nim/g/approximate_matching_greedy.nim`](../../../nim/g/approximate_matching_greedy.nim) |
| Odin | [`odin/g/approximate_matching_greedy.odin`](../../../odin/g/approximate_matching_greedy.odin) |
| Rust | [`rust/g/approximate_matching_greedy.rs`](../../../rust/g/approximate_matching_greedy.rs) |
| V | [`v/g/approximate_matching_greedy.v`](../../../v/g/approximate_matching_greedy.v) |
| Zig | [`zig/g/approximate_matching_greedy.zig`](../../../zig/g/approximate_matching_greedy.zig) |
