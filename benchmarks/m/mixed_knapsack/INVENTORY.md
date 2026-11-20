# Static inventory

Package: `mixed_knapsack`  
ABI: `i64_array_scalar`  
Input: `[n,capacity,(mode,weight,value,limit)*n]`, `n<=16`, capacity `0..64`  
Modes: 0/1 (`limit=1`), unbounded (`limit=0`), bounded (`limit=0..16`)  
Result: maximum total value within capacity; invalid `-1`  
Workspace: 1,024 bytes  
Valid / parseable lengths: 66 / 67 signed 64-bit values

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Per-mode update dispatch with bounded binary grouping |
| `independent_oracle.py` | Fresh-row direct copy-count dynamic program |
| `workload.json` | Mixed-mode, boundary, and malformed records |
| `verify_workload.py` | Static workload, oracle, and ten-port preflight |
| `check_inventory.py` | Static package artifact and port inventory |
| `README.md` | Contract, mode behavior, complexity, and local distinctions |
| `RIGHTS.md` | Clean-room provenance and source attribution |
| `c/m/mixed_knapsack.c` | C port |
| `c3/m/mixed_knapsack.c3` | C3 port |
| `cpp/m/mixed_knapsack.cpp` | C++ port |
| `elisa/m/mixed_knapsack.elisa` | Elisa port using a bounded input view and fixed DP array |
| `mojo/m/mixed_knapsack.mojo` | Mojo port |
| `nim/m/mixed_knapsack.nim` | Nim port |
| `odin/m/mixed_knapsack.odin` | Odin port |
| `rust/m/mixed_knapsack.rs` | Rust port |
| `v/m/mixed_knapsack.v` | V port |
| `zig/m/mixed_knapsack.zig` | Zig port |

Shared suite and root documentation are parent-owned. No executable checks
were run.
