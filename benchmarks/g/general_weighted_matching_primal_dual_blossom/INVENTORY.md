# Static inventory

Package: `general_weighted_matching_primal_dual_blossom`  
ABI: `i64_array_scalar`  
Exported symbol: `general_weighted_matching_primal_dual_blossom`  
Bounds: 1–64 vertices, at most 2016 simple undirected edges, positive i64
weights through 1,000,000; maximum valid packed input is 6050 words and the
workload parser limit is 6051 words.  
Workspace metadata: 524288 bytes, covering fixed primal-dual, blossom, edge,
and queue storage.  
Algorithm: weighted primal-dual blossom with tight-edge alternating forests,
odd-cycle contraction, dual adjustment, and inner-blossom expansion; cubic in
the vertex count.  
References: bottom-up subset-DP primary for small graphs; edge-subset
enumeration independent oracle for small fixtures; hand-derived objective
cases for the larger fixtures.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.  
Suite wiring: registered in `benchmarks/run_i64_array_scalar.py` and
`benchmarks/verify_i64_array_scalar.py`, with workload fixtures cross-checked
against the bounded primal-dual, subset-DP, and edge-subset references.

This inventory is a static source listing. No package checker or executable
validation is part of this draft.
