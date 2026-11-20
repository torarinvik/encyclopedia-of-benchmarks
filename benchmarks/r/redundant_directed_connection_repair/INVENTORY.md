# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Two-parent detection and DSU cycle resolution. |
| `independent_oracle.py` | Reverse-order edge deletion with directed arborescence checks. |
| `workload.json` | Valid, malformed, and ambiguous-removal fixtures. |
| `verify_workload.py` | Static metadata, fixture, oracle, and ten-port review. |
| `c/r/redundant_directed_connection_repair.c` | C port. |
| `c3/r/redundant_directed_connection_repair.c3` | C3 port. |
| `cpp/r/redundant_directed_connection_repair.cpp` | C++ port. |
| `elisa/r/redundant_directed_connection_repair.elisa` | Elisa port. |
| `mojo/r/redundant_directed_connection_repair.mojo` | Mojo port. |
| `nim/r/redundant_directed_connection_repair.nim` | Nim port. |
| `odin/r/redundant_directed_connection_repair.odin` | Odin port. |
| `rust/r/redundant_directed_connection_repair.rs` | Rust port. |
| `v/r/redundant_directed_connection_repair.v` | V port. |
| `zig/r/redundant_directed_connection_repair.zig` | Zig port. |

The shared `i64_array_scalar` runner and root catalog are owned separately.
