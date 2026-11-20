# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Timestamp batching with DSU and local reset. |
| `independent_oracle.py` | Time-slice graph propagation by BFS. |
| `workload.json` | Valid, malformed, and maximum-frame scalar fixtures. |
| `verify_workload.py` | Static metadata, fixture, oracle, and ten-port review. |
| `c/s/secret_sharing_time_batched_dsu.c` | C port. |
| `c3/s/secret_sharing_time_batched_dsu.c3` | C3 port. |
| `cpp/s/secret_sharing_time_batched_dsu.cpp` | C++ port. |
| `elisa/s/secret_sharing_time_batched_dsu.elisa` | Elisa port. |
| `mojo/s/secret_sharing_time_batched_dsu.mojo` | Mojo port. |
| `nim/s/secret_sharing_time_batched_dsu.nim` | Nim port. |
| `odin/s/secret_sharing_time_batched_dsu.odin` | Odin port. |
| `rust/s/secret_sharing_time_batched_dsu.rs` | Rust port. |
| `v/s/secret_sharing_time_batched_dsu.v` | V port. |
| `zig/s/secret_sharing_time_batched_dsu.zig` | Zig port. |

The shared `i64_array_scalar` runner and root catalog are owned separately.
