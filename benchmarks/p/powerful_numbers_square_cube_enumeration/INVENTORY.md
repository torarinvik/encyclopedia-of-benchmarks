# Package inventory

- Algorithm: `powerful_numbers_square_cube_enumeration`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (squarefree-`b` square/cube enumeration)
- Independent reference: `independent_oracle.py` (integer scan with trial factorization)
- Workload: `workload.json` (hand-pinned sequence prefixes, malformed input, and output errors)
- Static workload reconciliation: `verify_workload.py` (authored only; not run)
- Static path/metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite status: registered in `i64_array_bytes_output`.

The 512-byte workspace cap includes the 14-i64 value stage, in-place sorting
state, and bounded squarefree tests. Caller-owned input/output buffers are
excluded. Maximum output is 120 bytes. No package helper or benchmark was run.

| Language | Source |
|---|---|
| C | `c/p/powerful_numbers_square_cube_enumeration.c` |
| C3 | `c3/p/powerful_numbers_square_cube_enumeration.c3` |
| C++ | `cpp/p/powerful_numbers_square_cube_enumeration.cpp` |
| Elisa | `elisa/p/powerful_numbers_square_cube_enumeration.elisa` |
| Mojo | `mojo/p/powerful_numbers_square_cube_enumeration.mojo` |
| Nim | `nim/p/powerful_numbers_square_cube_enumeration.nim` |
| Odin | `odin/p/powerful_numbers_square_cube_enumeration.odin` |
| Rust | `rust/p/powerful_numbers_square_cube_enumeration.rs` |
| V | `v/p/powerful_numbers_square_cube_enumeration.v` |
| Zig | `zig/p/powerful_numbers_square_cube_enumeration.zig` |
