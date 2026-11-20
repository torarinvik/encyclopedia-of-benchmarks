# Package inventory

- Algorithm: `triangle_mesh_faces_from_edge_graph`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (incremental edge-incidence table)
- Independent reference: `independent_oracle.py` (recomputed incidences and scores)
- Workload: `workload.json` (hand-pinned seed, fallback, malformed, and output-error cases)
- Static workload reconciliation: `verify_workload.py` (authored only; not run)
- Static path/metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite status: integrated in the byte-output runner/verifier and root catalog/coverage records.

The maximum input frame is 59 i64 words, maximum candidate count is 56, the
maximum output cap is 1,360 bytes, and the declared workspace is 8,192 bytes.
The workspace includes fixed candidate, incidence, edge, and output-stage
arrays while excluding caller-owned input/output buffers. No package helper or
benchmark was run.

| Language | Source |
|---|---|
| C | `c/f/triangle_mesh_faces_from_edge_graph.c` |
| C3 | `c3/f/triangle_mesh_faces_from_edge_graph.c3` |
| C++ | `cpp/f/triangle_mesh_faces_from_edge_graph.cpp` |
| Elisa | `elisa/f/triangle_mesh_faces_from_edge_graph.elisa` |
| Mojo | `mojo/f/triangle_mesh_faces_from_edge_graph.mojo` |
| Nim | `nim/f/triangle_mesh_faces_from_edge_graph.nim` |
| Odin | `odin/f/triangle_mesh_faces_from_edge_graph.odin` |
| Rust | `rust/f/triangle_mesh_faces_from_edge_graph.rs` |
| V | `v/f/triangle_mesh_faces_from_edge_graph.v` |
| Zig | `zig/f/triangle_mesh_faces_from_edge_graph.zig` |
