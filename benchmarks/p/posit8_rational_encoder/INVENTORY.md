# Package inventory

- Algorithm: `posit8_rational_encoder`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (ordered-code binary search, exact
  scaled integer arithmetic)
- Independent reference: `independent_oracle.py` (full code-space scan with
  exact `Fraction` values)
- Workload: `workload.json` (hand-pinned exact values, ties, saturation,
  maximum valid batch, parser errors, and output errors)
- Workload reconciliation helper: `verify_workload.py` (authored only; not run)
- Static path/metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite status: registered in the shared byte-output runner, verifier, and catalog.

The declared workspace ceiling is 128 bytes, including the native 32-byte
staging array and bounded scalar/index temporaries. Caller-owned input and
output buffers are excluded. No codeword lookup table is allocated. No
package helper, native port, compiler, or test has been executed.

## Native source paths

| Language | Source |
| --- | --- |
| C | `c/p/posit8_rational_encoder.c` |
| C3 | `c3/p/posit8_rational_encoder.c3` |
| C++ | `cpp/p/posit8_rational_encoder.cpp` |
| Elisa | `elisa/p/posit8_rational_encoder.elisa` |
| Mojo | `mojo/p/posit8_rational_encoder.mojo` |
| Nim | `nim/p/posit8_rational_encoder.nim` |
| Odin | `odin/p/posit8_rational_encoder.odin` |
| Rust | `rust/p/posit8_rational_encoder.rs` |
| V | `v/p/posit8_rational_encoder.v` |
| Zig | `zig/p/posit8_rational_encoder.zig` |
