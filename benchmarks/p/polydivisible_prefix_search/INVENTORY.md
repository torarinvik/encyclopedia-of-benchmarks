# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded search contract and explicit depth tradeoff. |
| `RIGHTS.md` | Definition, discovery lead, and clean-room provenance. |
| `workload.json` | Base/depth fixtures, oracle checks, and malformed inputs. |
| `primary_oracle.py` | Recursive incremental prefix extension and count. |
| `independent_oracle.py` | Exhaustive numeric enumeration with direct prefix tests. |
| `verify_workload.py` | Static metadata, references, documentation, and port inventory review; not run. |
| `c/p/polydivisible_prefix_search.c` | C port. |
| `c3/p/polydivisible_prefix_search.c3` | C3 port. |
| `cpp/p/polydivisible_prefix_search.cpp` | C++ port. |
| `elisa/p/polydivisible_prefix_search.elisa` | Elisa port; recursive helper passes scalar values. |
| `mojo/p/polydivisible_prefix_search.mojo` | Mojo port. |
| `nim/p/polydivisible_prefix_search.nim` | Nim port. |
| `odin/p/polydivisible_prefix_search.odin` | Odin port. |
| `rust/p/polydivisible_prefix_search.rs` | Rust port with safe slice after the ABI boundary. |
| `v/p/polydivisible_prefix_search.v` | V port. |
| `zig/p/polydivisible_prefix_search.zig` | Zig port. |

All ten ports are source drafts and remain unbuilt and unexecuted. Shared
`i64_array_scalar` runner/verifier dispatch, package workload checks, and root
catalog entries are integrated as source; no executable checks were run.
