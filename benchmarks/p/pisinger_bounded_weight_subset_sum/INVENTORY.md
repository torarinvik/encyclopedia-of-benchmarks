# Static inventory

Package: `pisinger_bounded_weight_subset_sum`  
ABI: `i64_array_scalar`  
Input: `[n,target,weights...]`, `0<=n<=32`, `0<=target<=256`, each weight in
`1..12`  
Result: maximum subset sum not exceeding target; invalid input `-1`  
Workspace declaration: 1,024 bytes  
Valid / parseable lengths: 34 / 35 signed 64-bit values

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Pisinger BALSUB boundary-state recurrence |
| `independent_oracle.py` | Descending capacity-indexed reachability DP |
| `workload.json` | Hand-derived valid, boundary, and malformed records |
| `verify_workload.py` | Static workload shape and oracle consistency preflight |
| `check_inventory.py` | Static port inventory and required-source checks |
| `README.md` | Contract, complexity, source comparison, and ten port links |
| `RIGHTS.md` | Clean-room provenance and source licensing notes |
| `c/p/pisinger_bounded_weight_subset_sum.c` | C port |
| `c3/p/pisinger_bounded_weight_subset_sum.c3` | C3 port |
| `cpp/p/pisinger_bounded_weight_subset_sum.cpp` | C++ port |
| `elisa/p/pisinger_bounded_weight_subset_sum.elisa` | Elisa port with bounded state arrays |
| `mojo/p/pisinger_bounded_weight_subset_sum.mojo` | Mojo port |
| `nim/p/pisinger_bounded_weight_subset_sum.nim` | Nim port |
| `odin/p/pisinger_bounded_weight_subset_sum.odin` | Odin port |
| `rust/p/pisinger_bounded_weight_subset_sum.rs` | Rust port |
| `v/p/pisinger_bounded_weight_subset_sum.v` | V port |
| `zig/p/pisinger_bounded_weight_subset_sum.zig` | Zig port |

Suite registration and root catalog/README entries are owned by the parent.
No executable checks were run.
