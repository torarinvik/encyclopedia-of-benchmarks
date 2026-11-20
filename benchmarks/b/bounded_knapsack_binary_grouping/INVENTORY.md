# Static inventory

Package: `bounded_knapsack_binary_grouping`  
ABI: `i64_array_scalar`  
Input: `[n,capacity,(weight,value,count)*n]`, `n<=16`, capacity `0..64`,
weights `1..16`, values/counts `0..100` / `0..16`  
Result: maximum bounded-item value within capacity; invalid `-1`  
Workspace declaration: 1,024 bytes  
Valid / parseable lengths: 50 / 51 signed 64-bit values

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Binary grouping and descending 0/1 capacity updates |
| `independent_oracle.py` | Per-type copy-count dynamic programming |
| `workload.json` | Hand-derived, boundary, zero-count/value, and malformed records |
| `verify_workload.py` | Static workload, oracle, provenance, and source preflight |
| `check_inventory.py` | Static package artifact and ten-port inventory |
| `README.md` | Contract, binary bundle method, complexity, and source comparison |
| `RIGHTS.md` | Clean-room provenance and source license note |
| `c/b/bounded_knapsack_binary_grouping.c` | C port |
| `c3/b/bounded_knapsack_binary_grouping.c3` | C3 port |
| `cpp/b/bounded_knapsack_binary_grouping.cpp` | C++ port |
| `elisa/b/bounded_knapsack_binary_grouping.elisa` | Elisa port using a bounded view and fixed DP array |
| `mojo/b/bounded_knapsack_binary_grouping.mojo` | Mojo port |
| `nim/b/bounded_knapsack_binary_grouping.nim` | Nim port |
| `odin/b/bounded_knapsack_binary_grouping.odin` | Odin port |
| `rust/b/bounded_knapsack_binary_grouping.rs` | Rust port |
| `v/b/bounded_knapsack_binary_grouping.v` | V port |
| `zig/b/bounded_knapsack_binary_grouping.zig` | Zig port |

Shared scalar-suite integration and root docs are owned by the parent. No
executable checks were run.
