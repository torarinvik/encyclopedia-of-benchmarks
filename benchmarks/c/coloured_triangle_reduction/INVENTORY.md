# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Reduction contract and closed-form explanation. |
| `RIGHTS.md` | Idea-index boundary and mathematical provenance. |
| `workload.json` | Bounded valid, Lucas-digit, and malformed fixtures. |
| `primary_oracle.py` | Closed-form binomial sum with base-three Lucas coefficients. |
| `independent_oracle.py` | Direct repeated adjacent-pair reduction. |
| `verify_workload.py` | Static metadata, dual-reference, documentation, and port inventory review; not run. |
| `c/c/coloured_triangle_reduction.c` | C port. |
| `c3/c/coloured_triangle_reduction.c3` | C3 port. |
| `cpp/c/coloured_triangle_reduction.cpp` | C++ port. |
| `elisa/c/coloured_triangle_reduction.elisa` | Elisa port with safe scalar-indexed array view at the ABI boundary. |
| `mojo/c/coloured_triangle_reduction.mojo` | Mojo port. |
| `nim/c/coloured_triangle_reduction.nim` | Nim port. |
| `odin/c/coloured_triangle_reduction.odin` | Odin port. |
| `rust/c/coloured_triangle_reduction.rs` | Rust port using a safe slice after the ABI boundary. |
| `v/c/coloured_triangle_reduction.v` | V port. |
| `zig/c/coloured_triangle_reduction.zig` | Zig port. |

All ten ports are source drafts and remain unbuilt and unexecuted. Shared
`i64_array_scalar` runner/verifier dispatch, package workload checks, and root
catalog entries are integrated as source; no executable checks were run.
