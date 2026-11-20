# Package inventory

- Algorithm: `goodstein_sequence_bounded_prefix`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (recursive numeric hereditary rebase)
- Independent reference: `independent_oracle.py` (symbolic expression tree and evaluator)
- Workload: `workload.json` (small fixed points, a one-to-zero sequence, bounded prefixes, malformed input, and output errors)
- Static workload reconciliation: `verify_workload.py` (authored only; not run)
- Static path and metadata inventory: `check_inventory.py` (authored only; not run)
- Rights/provenance: `RIGHTS.md`
- Shared suite status: registered in `i64_array_bytes_output`.

The native workspace cap is 512 bytes. It includes the 17-i64 term stage,
recursive base-conversion state, and scalar/index state. Caller-owned input and
output are excluded. The maximum serialized output is 144 bytes. No project
program or validation helper has been run.

| Language | Source |
|---|---|
| C | `c/g/goodstein_sequence_bounded_prefix.c` |
| C3 | `c3/g/goodstein_sequence_bounded_prefix.c3` |
| C++ | `cpp/g/goodstein_sequence_bounded_prefix.cpp` |
| Elisa | `elisa/g/goodstein_sequence_bounded_prefix.elisa` |
| Mojo | `mojo/g/goodstein_sequence_bounded_prefix.mojo` |
| Nim | `nim/g/goodstein_sequence_bounded_prefix.nim` |
| Odin | `odin/g/goodstein_sequence_bounded_prefix.odin` |
| Rust | `rust/g/goodstein_sequence_bounded_prefix.rs` |
| V | `v/g/goodstein_sequence_bounded_prefix.v` |
| Zig | `zig/g/goodstein_sequence_bounded_prefix.zig` |
