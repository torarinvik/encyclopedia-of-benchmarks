# General-graph maximum-cardinality matching

This package implements a deterministic Edmonds augmenting-path/blossom
algorithm for maximum-cardinality matching in a simple undirected graph. The
search scans vertices and neighbors in ascending ID order. The ABI returns
the maximum matching cardinality; it does not serialize the matching witness.
This keeps the result independent of which maximum witness is selected when
several exist.

## Contract

ABI: `i64_array_bytes_output`; symbol: `general_graph_maximum_matching`.
Input is `[n,m,(u,v)[m]]`, with `2<=n<=12`, `0<=m<=n(n-1)/2`, and each edge
listed once as `0<=u<v<n`. The graph is general, not necessarily bipartite.
Input maximum is 134 signed 64-bit words. Output is one little-endian signed
64-bit word: the maximum matching size, so the maximum output is 8 bytes.
Malformed input returns `-1` before output checks; null or short output returns
`-2` without writes.

## Source and scope

Based on Marcin Mucha, “Maximum Matching,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_225`](https://doi.org/10.1007/978-1-4939-2864-4_225).
The chapter describes Edmonds’ O(n^3) combinatorial method using augmenting
paths and blossoms. This package is that deterministic bounded general-graph
profile. It does not implement the chapter’s randomized algebraic Mucha–
Sankowski results or weighted/perfect-matching variants. The ports contain no
copied book text or code; see [`RIGHTS.md`](RIGHTS.md).

The primary oracle is
[`general_graph_maximum_matching_oracle.py`](../../general_graph_maximum_matching_oracle.py).
The independent subset-DP verifier is
[`general_graph_maximum_matching_verifier_oracle.py`](../../general_graph_maximum_matching_verifier_oracle.py).
Fixtures are in [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | `c/g/general_graph_maximum_matching.c` |
| C3 | `c3/g/general_graph_maximum_matching.c3` |
| C++ | `cpp/g/general_graph_maximum_matching.cpp` |
| Elisa | `elisa/g/general_graph_maximum_matching.elisa` |
| Nim | `nim/g/general_graph_maximum_matching.nim` |
| Odin | `odin/g/general_graph_maximum_matching.odin` |
| Rust | `rust/g/general_graph_maximum_matching.rs` |
| V | `v/g/general_graph_maximum_matching.v` |
| Zig | `zig/g/general_graph_maximum_matching.zig` |
