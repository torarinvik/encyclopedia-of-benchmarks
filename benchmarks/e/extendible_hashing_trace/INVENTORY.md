# Static inventory

Algorithm: `extendible_hashing_trace`  
ABI: `i64_array_scalar`  
Input: `[Q,(opcode,key)*Q]`, Q 0–40, keys 0–255  
Valid/parseable lengths: 81/82 words  
Output: success mask and final bucket/depth/live-key fields in bits 0–62; valid result upper bound 5,841,451,291,187,871,743; `-1` for malformed input  
Depth cap: 8  
Workspace cap: 8,192 bytes

| Language | Source | Exported symbol |
|---|---|---|
| C | `c/e/extendible_hashing_trace.c` | `extendible_hashing_trace` |
| C3 | `c3/e/extendible_hashing_trace.c3` | `extendible_hashing_trace` |
| C++ | `cpp/e/extendible_hashing_trace.cpp` | `extendible_hashing_trace` |
| Elisa | `elisa/e/extendible_hashing_trace.elisa` | `extendible_hashing_trace` |
| Mojo | `mojo/e/extendible_hashing_trace.mojo` | `extendible_hashing_trace` |
| Nim | `nim/e/extendible_hashing_trace.nim` | `extendible_hashing_trace` |
| Odin | `odin/e/extendible_hashing_trace.odin` | `extendible_hashing_trace` |
| Rust | `rust/e/extendible_hashing_trace.rs` | `extendible_hashing_trace` |
| V | `v/e/extendible_hashing_trace.v` | `extendible_hashing_trace` |
| Zig | `zig/e/extendible_hashing_trace.zig` | `extendible_hashing_trace` |

Metadata: `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`,
`workload.json`, `primary_oracle.py`, `independent_oracle.py`,
`verify_workload.py`, and `check_inventory.py`.
