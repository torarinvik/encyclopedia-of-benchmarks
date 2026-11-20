# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded prefix contract and algorithm distinction. |
| `RIGHTS.md` | Mathematical provenance and clean-room note. |
| `workload.json` | Prefix lengths, packing order, boundary and invalid-input fixtures. |
| `primary_oracle.py` | Per-index MSB-first zero-parity automaton. |
| `independent_oracle.py` | Binary-string maximal-zero-run reference. |
| `verify_workload.py` | Static workload, metadata, link, dual-reference, and source inventory review; not run. |
| `c/b/baum_sweet_sequence.c` | C port. |
| `c3/b/baum_sweet_sequence.c3` | C3 port. |
| `cpp/b/baum_sweet_sequence.cpp` | C++ port. |
| `elisa/b/baum_sweet_sequence.elisa` | Elisa port; the FFI pointer is converted to a bounded safe view before indexing. |
| `mojo/b/baum_sweet_sequence.mojo` | Mojo port. |
| `nim/b/baum_sweet_sequence.nim` | Nim port. |
| `odin/b/baum_sweet_sequence.odin` | Odin port. |
| `rust/b/baum_sweet_sequence.rs` | Rust port using a safe slice after the ABI boundary. |
| `v/b/baum_sweet_sequence.v` | V port. |
| `zig/b/baum_sweet_sequence.zig` | Zig port. |

All ten ports are source drafts and remain unbuilt and unexecuted. Shared
`i64_array_scalar` runner/verifier dispatch, workload checks, and catalog entry
are integrated as source; no executable checks were run.
