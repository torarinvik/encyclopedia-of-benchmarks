# Static inventory

ABI: `i64_array_scalar`  
Symbol: `entringer_number`  
Input: `[n,k]`, `0<=n<=12`, `0<=k<=n`; invalid result `-1`.  
Output: exact signed-i64 Entringer number `E(n,k)`.  
Native workspace cap: 512 bytes; two fixed rows of 13 i64 values occupy 208 bytes.

| Language | Source |
|---|---|
| C | `c/e/entringer_number.c` |
| C3 | `c3/e/entringer_number.c3` |
| C++ | `cpp/e/entringer_number.cpp` |
| Elisa | `elisa/e/entringer_number.elisa` |
| Mojo | `mojo/e/entringer_number.mojo` |
| Nim | `nim/e/entringer_number.nim` |
| Odin | `odin/e/entringer_number.odin` |
| Rust | `rust/e/entringer_number.rs` |
| V | `v/e/entringer_number.v` |
| Zig | `zig/e/entringer_number.zig` |

Package artifacts: `README.md`, `RIGHTS.md`, `workload.json`, `primary_oracle.py`, `independent_oracle.py`, `verify_workload.py`, and `check_inventory.py`. Suite and catalog wiring are root-owned.
