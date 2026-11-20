# Static inventory

Algorithm: `frobenius_number_apery`  
ABI: `i64_array_scalar`  
Valid input: `[m, denominations...]`, 3–5 words  
Parseable input cap: 6 words  
Output: one signed i64 Frobenius number, or `-1` for invalid input  
Valid denomination count: 2–4  
Valid denomination range: 2–16, distinct, gcd 1  
Largest valid output: 209  
Kernel workspace cap: 256 bytes (192 bytes maximum explicit native state)

| Language | Path | Exported symbol |
| --- | --- | --- |
| C | `c/f/frobenius_number_apery.c` | `frobenius_number_apery` |
| C3 | `c3/f/frobenius_number_apery.c3` | `frobenius_number_apery` |
| C++ | `cpp/f/frobenius_number_apery.cpp` | `frobenius_number_apery` |
| Elisa | `elisa/f/frobenius_number_apery.elisa` | `frobenius_number_apery` |
| Mojo | `mojo/f/frobenius_number_apery.mojo` | `frobenius_number_apery` |
| Nim | `nim/f/frobenius_number_apery.nim` | `frobenius_number_apery` |
| Odin | `odin/f/frobenius_number_apery.odin` | `frobenius_number_apery` |
| Rust | `rust/f/frobenius_number_apery.rs` | `frobenius_number_apery` |
| V | `v/f/frobenius_number_apery.v` | `frobenius_number_apery` |
| Zig | `zig/f/frobenius_number_apery.zig` | `frobenius_number_apery` |

Package metadata includes `workload.json`, `primary_oracle.py`,
`independent_oracle.py`, `verify_workload.py`, `check_inventory.py`, `README.md`,
and `RIGHTS.md`. The ten ports are registered in the shared
`i64_array_scalar` runner and verifier. This inventory is source-only; no port
or checker was run.
