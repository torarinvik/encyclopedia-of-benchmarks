# Package inventory

- Algorithm: `brownian_tree_diffusion_limited_aggregation`
- ABI: `i64_array_bytes_output`
- Native ports: [C](../../../c/b/brownian_tree_diffusion_limited_aggregation.c), [C3](../../../c3/b/brownian_tree_diffusion_limited_aggregation.c3), [C++](../../../cpp/b/brownian_tree_diffusion_limited_aggregation.cpp), [Elisa](../../../elisa/b/brownian_tree_diffusion_limited_aggregation.elisa), [Mojo](../../../mojo/b/brownian_tree_diffusion_limited_aggregation.mojo), [Nim](../../../nim/b/brownian_tree_diffusion_limited_aggregation.nim), [Odin](../../../odin/b/brownian_tree_diffusion_limited_aggregation.odin), [Rust](../../../rust/b/brownian_tree_diffusion_limited_aggregation.rs), [V](../../../v/b/brownian_tree_diffusion_limited_aggregation.v), [Zig](../../../zig/b/brownian_tree_diffusion_limited_aggregation.zig)
- Primary reference: `primary_oracle.py` (online DLA with bitmap adjacency)
- Independent reference: `independent_oracle.py` (per-attempt path precomputation and occupied-point scans)
- Workload: `workload.json`
- Workload/reference verifier: `verify_workload.py` (Python references only; no native port loading)
- Rights and provenance: `RIGHTS.md`
- Static inventory helper: `check_inventory.py`

The workspace ceiling is 2,048 bytes. The largest native fixed state is the C3 occupancy bitmap plus coordinate arrays (1,361 bytes); scalar state fits in the remaining allowance. `check_inventory.py` checks paths, symbols, declared bounds, and fixture metadata only. `verify_workload.py` compares expected workload results against the two Python references; neither helper calls native ports.
