# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded tree, operation, checksum, and result contract. |
| `RIGHTS.md` | OI Wiki provenance and clean-room statement. |
| `workload.json` | Valid operation traces and malformed frames. |
| `primary_oracle.py` | Centroid decomposition with per-branch active maxima. |
| `independent_oracle.py` | BFS all-pairs distances and direct active-pair scans. |
| `verify_workload.py` | Static artifact, port, metadata, provenance, and dual-reference review; not run. |
| `c/d/dynamic_centroid_active_set_diameter.c` | C port. |
| `c3/d/dynamic_centroid_active_set_diameter.c3` | C3 port. |
| `cpp/d/dynamic_centroid_active_set_diameter.cpp` | C++ port. |
| `elisa/d/dynamic_centroid_active_set_diameter.elisa` | Elisa port using safe array views after the ABI boundary. |
| `mojo/d/dynamic_centroid_active_set_diameter.mojo` | Mojo port. |
| `nim/d/dynamic_centroid_active_set_diameter.nim` | Nim port. |
| `odin/d/dynamic_centroid_active_set_diameter.odin` | Odin port. |
| `rust/d/dynamic_centroid_active_set_diameter.rs` | Rust port using a safe slice after the ABI boundary. |
| `v/d/dynamic_centroid_active_set_diameter.v` | V port. |
| `zig/d/dynamic_centroid_active_set_diameter.zig` | Zig port. |

All ten implementations are source drafts. Shared suite and root documentation
integration remain outside this package task. No executable checks have been
run.
