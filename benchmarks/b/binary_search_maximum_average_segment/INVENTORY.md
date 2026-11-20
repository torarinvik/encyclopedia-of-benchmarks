# Static inventory

Package: `binary_search_maximum_average_segment`  
ABI: `i64_array_scalar`  
Input: `[n,L,values...]`, `1<=n<=32`, `1<=L<=n`, values in `[-1000,1000]`  
Result: `floor(1000 * maximum average among intervals of length >= L)`; invalid `-1000001`  
Workspace declaration: 1,024 bytes  
Valid / parseable lengths: 34 / 35 signed 64-bit values

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Integer-threshold binary search with transformed-prefix feasibility |
| `independent_oracle.py` | Exact interval enumeration and cross-multiplied average comparison |
| `workload.json` | Hand-derived valid, boundary, and malformed records |
| `verify_workload.py` | Static workload and reference inventory preflight |
| `check_inventory.py` | Static package artifact and ten-port inventory |
| `README.md` | Contract, method, complexity, sources, and port links |
| `RIGHTS.md` | Clean-room provenance and source note |
| `c/b/binary_search_maximum_average_segment.c` | C port |
| `c3/b/binary_search_maximum_average_segment.c3` | C3 port |
| `cpp/b/binary_search_maximum_average_segment.cpp` | C++ port |
| `elisa/b/binary_search_maximum_average_segment.elisa` | Elisa port using a bounded input view and fixed prefix array |
| `mojo/b/binary_search_maximum_average_segment.mojo` | Mojo port |
| `nim/b/binary_search_maximum_average_segment.nim` | Nim port |
| `odin/b/binary_search_maximum_average_segment.odin` | Odin port |
| `rust/b/binary_search_maximum_average_segment.rs` | Rust port |
| `v/b/binary_search_maximum_average_segment.v` | V port |
| `zig/b/binary_search_maximum_average_segment.zig` | Zig port |

The shared scalar suite and root catalog/README integration are owned by the
parent. No executable checks were run.
