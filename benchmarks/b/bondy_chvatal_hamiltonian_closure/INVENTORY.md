# Package inventory

- Algorithm: `bondy_chvatal_hamiltonian_closure`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (sequential lexicographic pair addition)
- Independent reference: `independent_oracle.py` (synchronous eligible-edge rounds)
- Workload: `workload.json` (hand-pinned valid and ABI cases)
- Static workload reconciliation: `verify_workload.py` (authored only; not run)
- Static package inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared byte-output runner, verifier, and catalog integration: complete.

The input cap is 58 valid / 59 parseable i64 words; output is at most 80 bytes;
workspace is bounded at 1,024 bytes. Workspace covers adjacency, degree, and
staged output arrays; caller-owned input/output buffers are excluded. No helper
or benchmark was run.

| Language | Source |
|---|---|
| C | `c/b/bondy_chvatal_hamiltonian_closure.c` |
| C3 | `c3/b/bondy_chvatal_hamiltonian_closure.c3` |
| C++ | `cpp/b/bondy_chvatal_hamiltonian_closure.cpp` |
| Elisa | `elisa/b/bondy_chvatal_hamiltonian_closure.elisa` |
| Mojo | `mojo/b/bondy_chvatal_hamiltonian_closure.mojo` |
| Nim | `nim/b/bondy_chvatal_hamiltonian_closure.nim` |
| Odin | `odin/b/bondy_chvatal_hamiltonian_closure.odin` |
| Rust | `rust/b/bondy_chvatal_hamiltonian_closure.rs` |
| V | `v/b/bondy_chvatal_hamiltonian_closure.v` |
| Zig | `zig/b/bondy_chvatal_hamiltonian_closure.zig` |
