# Package inventory

`inventory.json` records the machine-readable file list and bounded ABI.
`check_inventory.py` checks package metadata and source-file presence without
building or executing benchmark implementations.

| Role | File |
|---|---|
| Primary source-ordered reference | `primary_oracle.py` |
| Independent violation-trace reference | `independent_oracle.py` |
| Bounded replay fixtures | `workload.json` |
| Provenance and rights | `RIGHTS.md` |
| Static inventory checker | `check_inventory.py` |
| C port | `c/b/blr_linearity_test.c` |
| C3 port | `c3/b/blr_linearity_test.c3` |
| C++ port | `cpp/b/blr_linearity_test.cpp` |
| Elisa port | `elisa/b/blr_linearity_test.elisa` |
| Mojo port | `mojo/b/blr_linearity_test.mojo` |
| Nim port | `nim/b/blr_linearity_test.nim` |
| Odin port | `odin/b/blr_linearity_test.odin` |
| Rust port | `rust/b/blr_linearity_test.rs` |
| V port | `v/b/blr_linearity_test.v` |
| Zig port | `zig/b/blr_linearity_test.zig` |

All source paths are relative to the repository root. This inventory is a
static review aid; no checker or benchmark was run while preparing it.
