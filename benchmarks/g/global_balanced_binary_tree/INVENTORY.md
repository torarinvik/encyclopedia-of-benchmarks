# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded static GBST contract, tie rules, checksum, and limits. |
| `RIGHTS.md` | OI Wiki provenance and clean-room statement. |
| `workload.json` | Valid tree shapes and malformed input fixtures. |
| `primary_oracle.py` | Parent-order subtree accumulation and weighted binary midpoint construction. |
| `independent_oracle.py` | Descendant-walk subtree calculation and linear pivot selection. |
| `verify_workload.py` | Static package, workload, source, and dual-reference review; not run. |
| `benchmarks/run_i64_array_scalar.py` | Primary-oracle validation and workload/static-package dispatch. |
| `benchmarks/verify_i64_array_scalar.py` | Independent-oracle dispatch, bounded tree corpus, workload validation, and parseable-length handling. |
| `README.md`, `CATALOG.md` | Root guide and catalog entries. |
| `c/g/global_balanced_binary_tree.c` | C port. |
| `c3/g/global_balanced_binary_tree.c3` | C3 port. |
| `cpp/g/global_balanced_binary_tree.cpp` | C++ port. |
| `elisa/g/global_balanced_binary_tree.elisa` | Elisa port using fixed arrays and the scalar ABI boundary. |
| `mojo/g/global_balanced_binary_tree.mojo` | Mojo port using fixed-capacity arrays. |
| `nim/g/global_balanced_binary_tree.nim` | Nim port. |
| `odin/g/global_balanced_binary_tree.odin` | Odin port. |
| `rust/g/global_balanced_binary_tree.rs` | Rust port with a safe slice after the ABI boundary. |
| `v/g/global_balanced_binary_tree.v` | V port. |
| `zig/g/global_balanced_binary_tree.zig` | Zig port. |

All ten implementations and suite/documentation registrations are present in
source. No executable checks have been run.
