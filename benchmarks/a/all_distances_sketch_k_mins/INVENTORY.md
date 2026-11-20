# Static inventory

Algorithm profile: `all_distances_sketch_k_mins`
(`i64_array_bytes_output`).

| Language | Source | Exported symbol |
|---|---|---|
| C | `c/a/all_distances_sketch_k_mins.c` | `all_distances_sketch_k_mins` |
| C3 | `c3/a/all_distances_sketch_k_mins.c3` | `all_distances_sketch_k_mins` |
| C++ | `cpp/a/all_distances_sketch_k_mins.cpp` | `all_distances_sketch_k_mins` |
| Elisa | `elisa/a/all_distances_sketch_k_mins.elisa` | `all_distances_sketch_k_mins` |
| Mojo | `mojo/a/all_distances_sketch_k_mins.mojo` | `all_distances_sketch_k_mins` |
| Nim | `nim/a/all_distances_sketch_k_mins.nim` | `all_distances_sketch_k_mins` |
| Odin | `odin/a/all_distances_sketch_k_mins.odin` | `all_distances_sketch_k_mins` |
| Rust | `rust/a/all_distances_sketch_k_mins.rs` | `all_distances_sketch_k_mins` |
| V | `v/a/all_distances_sketch_k_mins.v` | `all_distances_sketch_k_mins` |
| Zig | `zig/a/all_distances_sketch_k_mins.zig` | `all_distances_sketch_k_mins` |

Metadata: `README.md`, `RIGHTS.md`, `workload.json`, `primary_oracle.py`,
`independent_oracle.py`, `INVENTORY.json`, and `check_inventory.py`.

The primary reference scans each rank row and emits strict prefix minima. The
independent reference evaluates every distance-prefix query and emits each
change in the minimum-rank answer. The two algorithms compute the same MV/D
four-field records by different traversals. The ten ports are registered with
the `i64_array_bytes_output` runner and verifier. No executable checks have been run.
