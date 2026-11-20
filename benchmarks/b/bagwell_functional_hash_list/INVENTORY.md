# Static inventory

| Item | Status |
|---|---|
| Contract, references, workload fixtures, provenance, and package guide | Complete; manually reconciled |
| C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig ports | Present; manually reconciled |
| Shared byte-output suite, catalog, and coverage registration | Complete |

The profile bounds valid frames to 130 i64 words, parseable frames to 131,
output to 256 bytes, and workspace to 4,096 bytes. It follows Bagwell's
geometric block sides 8, 16, and 32. The independent reference scans each
snapshot's visible prefix newest-first; the primary uses block-local hash
chains and explicit block history. Package paths and references are listed
in `INVENTORY.json`. No programs or checks have been run.
