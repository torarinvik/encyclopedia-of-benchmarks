# Static inventory

- ABI: `i64_array_scalar`.
- Exported symbol: `bipartite_minimum_vertex_cover`.
- Input: `[left_count, right_count, left_adjacency_mask_0, ...]`; each side has at most 8 vertices.
- Output: packed minimum-cover mask, canonicalized by the lexicographically smallest membership vector; malformed input returns `-1`.
- Primary reference: ordered Kuhn matching, alternating reachability, and matching-feasibility refinement.
- Independent reference: exhaustive vertex-subset cover enumeration and canonical tie selection.
- Workload: `workload.json`, including isolated partitions, multiple-cover ties, mixed cover, maximum-size complete graph, malformed frames, and null input.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Workspace: 8,192 bytes.
- Provenance: KACTL `MinimumVertexCover.h` and `DFSMatching.h` descriptions; clean-room source.
- Distinction: returns a concrete canonical minimum-cover certificate; Dulmage–Mendelsohn returns E/O/U classes, while greedy/general cover packages solve different profiles.
- Package checker: `verify_workload.py` will perform static metadata/workload/source inventory checks; it has not been run.
- Scalar suite registration: `benchmarks/run_i64_array_scalar.py` and `benchmarks/verify_i64_array_scalar.py`.
- No programs, tests, scripts, checkers, builds, compilers, benchmarks, or profilers have been run.
