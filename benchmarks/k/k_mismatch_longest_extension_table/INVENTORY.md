# Package inventory

Algorithm: `k_mismatch_longest_extension_table`  
ABI: `i64_array_bytes_output`  
Input: `[n,K,w0,...,w(n-1)]`, 1–64 symbols in `0..25`, budget 0–4.  
Output: `n*(K+1)` raw bytes, each the `LP_k(p)` value in row-major order.  
Limits: 66 valid input words, 67 parseable input words, 320 output bytes,
8,192 workspace bytes.

| Language | Source |
|---|---|
| C | `c/k/k_mismatch_longest_extension_table.c` |
| C3 | `c3/k/k_mismatch_longest_extension_table.c3` |
| C++ | `cpp/k/k_mismatch_longest_extension_table.cpp` |
| Elisa | `elisa/k/k_mismatch_longest_extension_table.elisa` |
| Mojo | `mojo/k/k_mismatch_longest_extension_table.mojo` |
| Nim | `nim/k/k_mismatch_longest_extension_table.nim` |
| Odin | `odin/k/k_mismatch_longest_extension_table.odin` |
| Rust | `rust/k/k_mismatch_longest_extension_table.rs` |
| V | `v/k/k_mismatch_longest_extension_table.v` |
| Zig | `zig/k/k_mismatch_longest_extension_table.zig` |

Package files: `primary_oracle.py`, `independent_oracle.py`, `workload.json`,
`verify_workload.py`, `check_inventory.py`, `README.md`, and `RIGHTS.md`.
