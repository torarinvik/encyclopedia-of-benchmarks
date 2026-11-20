# Static package inventory

ABI: `i64_array_bytes_output`; symbol:
`k_quadtree_sampled_point_subdivision(input, length, output, capacity)`.
Input bound: 67 valid / 68 parseable i64 words. Output bound: 504 bytes.
Workspace bound: 4,096 bytes, excluding caller buffers.

References: [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). Static metadata helpers:
[`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py). These helpers are included for
later static validation and have not been run.

| Language | Source |
| --- | --- |
| C | [`c/k/k_quadtree_sampled_point_subdivision.c`](../../../c/k/k_quadtree_sampled_point_subdivision.c) |
| C3 | [`c3/k/k_quadtree_sampled_point_subdivision.c3`](../../../c3/k/k_quadtree_sampled_point_subdivision.c3) |
| C++ | [`cpp/k/k_quadtree_sampled_point_subdivision.cpp`](../../../cpp/k/k_quadtree_sampled_point_subdivision.cpp) |
| Elisa | [`elisa/k/k_quadtree_sampled_point_subdivision.elisa`](../../../elisa/k/k_quadtree_sampled_point_subdivision.elisa) |
| Mojo | [`mojo/k/k_quadtree_sampled_point_subdivision.mojo`](../../../mojo/k/k_quadtree_sampled_point_subdivision.mojo) |
| Nim | [`nim/k/k_quadtree_sampled_point_subdivision.nim`](../../../nim/k/k_quadtree_sampled_point_subdivision.nim) |
| Odin | [`odin/k/k_quadtree_sampled_point_subdivision.odin`](../../../odin/k/k_quadtree_sampled_point_subdivision.odin) |
| Rust | [`rust/k/k_quadtree_sampled_point_subdivision.rs`](../../../rust/k/k_quadtree_sampled_point_subdivision.rs) |
| V | [`v/k/k_quadtree_sampled_point_subdivision.v`](../../../v/k/k_quadtree_sampled_point_subdivision.v) |
| Zig | [`zig/k/k_quadtree_sampled_point_subdivision.zig`](../../../zig/k/k_quadtree_sampled_point_subdivision.zig) |

Shared `i64_array_bytes_output` runner/verifier and catalog registration are
complete. The suite helpers have not been run.
