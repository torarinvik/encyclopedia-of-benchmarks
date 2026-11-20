# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded incremental method, checksum, limits, and provenance. |
| `RIGHTS.md` | OI Wiki source attribution and clean-room scope. |
| `workload.json` | Valid, malformed, and profile input records. |
| `primary_oracle.py` | Range-add/min segment tree with monotone and node stacks. |
| `independent_oracle.py` | Explicit connected-interval enumeration and overlap filtering. |
| `verify_workload.py` | Static workload, metadata, references, and source inventory checks; not run. |
| `c/d/divide_combine_tree_incremental.c` | C port. |
| `c3/d/divide_combine_tree_incremental.c3` | C3 port. |
| `cpp/d/divide_combine_tree_incremental.cpp` | C++ port. |
| `elisa/d/divide_combine_tree_incremental.elisa` | Elisa port using fixed arrays. |
| `mojo/d/divide_combine_tree_incremental.mojo` | Mojo port using fixed-capacity arrays. |
| `nim/d/divide_combine_tree_incremental.nim` | Nim port. |
| `odin/d/divide_combine_tree_incremental.odin` | Odin port. |
| `rust/d/divide_combine_tree_incremental.rs` | Rust port. |
| `v/d/divide_combine_tree_incremental.v` | V port. |
| `zig/d/divide_combine_tree_incremental.zig` | Zig port. |

All package artifacts and ten source ports are present. They have only been
reviewed statically; no programs or checks have been run.
