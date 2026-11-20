# Package inventory

- Algorithm: `ring_expander_closed_triangle_mesh`
- Chapter/source: Encyclopedia of Algorithms, Chapter 589; Gurung et al.,
  ACM TOG 30(4), Article 67 (2011), §4.2, DOI 10.1145/1964921.1964962
- ABI/symbol: `i64_array_bytes_output` / `ring_expander_closed_triangle_mesh`
- Bounds: `n<=12`, `t<=20`; valid input 63 i64 words, parser ceiling 64
- Output: at most 504 bytes
- Workspace cap: 8,192 bytes
- Work: edge-incidence/opposite setup `O(t+v^2)`, dense link validation `O(v^3)`, Ring-Expander pass `O(t)`
- Source-level peak account: 5,816 bytes including face/trace buffers, a possible fixed-array argument copy, edge/link tables, queues, marks, and 512 bytes for scalar/serialization locals
- Workload: `workload.json`
- Static helpers: `check_inventory.py` (`check_inventory`, `static_issues`) and
  `verify_workload.py` (`verify_workload`, `workload_issues`)
- Primary oracle: `benchmarks/ring_expander_closed_triangle_mesh_oracle.py`
- Independent oracle: `benchmarks/ring_expander_closed_triangle_mesh_verifier_oracle.py`
- Rights/provenance: `RIGHTS.md`

| Language | Source |
|---|---|
| C | `c/r/ring_expander_closed_triangle_mesh.c` |
| C3 | `c3/r/ring_expander_closed_triangle_mesh.c3` |
| C++ | `cpp/r/ring_expander_closed_triangle_mesh.cpp` |
| Elisa | `elisa/r/ring_expander_closed_triangle_mesh.elisa` |
| Mojo | `mojo/r/ring_expander_closed_triangle_mesh.mojo` |
| Nim | `nim/r/ring_expander_closed_triangle_mesh.nim` |
| Odin | `odin/r/ring_expander_closed_triangle_mesh.odin` |
| Rust | `rust/r/ring_expander_closed_triangle_mesh.rs` |
| V | `v/r/ring_expander_closed_triangle_mesh.v` |
| Zig | `zig/r/ring_expander_closed_triangle_mesh.zig` |

Status: package-local source draft; shared suite/catalog integration is root-owned.
