# Static inventory

Package contract and generated-case boundary: `README.md`, `workload.json`.
Provenance and reuse boundaries: `RIGHTS.md`.
Primary and structurally independent references: `primary_oracle.py`,
`independent_oracle.py`.
Language ports, all exporting `nonogram_line_domain_solver`:

- `c/n/nonogram_line_domain_solver.c`
- `c3/n/nonogram_line_domain_solver.c3`
- `cpp/n/nonogram_line_domain_solver.cpp`
- `elisa/n/nonogram_line_domain_solver.elisa`
- `mojo/n/nonogram_line_domain_solver.mojo`
- `nim/n/nonogram_line_domain_solver.nim`
- `odin/n/nonogram_line_domain_solver.odin`
- `rust/n/nonogram_line_domain_solver.rs`
- `v/n/nonogram_line_domain_solver.v`
- `zig/n/nonogram_line_domain_solver.zig`

The shared `i64_array_bytes_output` runner and verifier dispatch use the primary
and independent references, the 64-byte output bound, and the package's static
source inventory. No language port, workload checker, test, build, or benchmark
has been executed.
