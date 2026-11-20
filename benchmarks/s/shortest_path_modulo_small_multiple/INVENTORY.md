# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Residue graph, bounded contract, and shortest-path profile. |
| `RIGHTS.md` | OI Wiki attribution and clean-room provenance. |
| `workload.json` | Valid, boundary, malformed, and null input fixtures. |
| `primary_oracle.py` | 0-1 BFS on residues. |
| `independent_oracle.py` | Exhaustive bounded enumeration of leading-one strings. |
| `verify_workload.py` | Static metadata, fixture, documentation, and port inventory review; not run. |
| `c/s/shortest_path_modulo_small_multiple.c` | C implementation. |
| `c3/s/shortest_path_modulo_small_multiple.c3` | C3 implementation. |
| `cpp/s/shortest_path_modulo_small_multiple.cpp` | C++ implementation. |
| `elisa/s/shortest_path_modulo_small_multiple.elisa` | Elisa implementation with a slice-based internal helper. |
| `mojo/s/shortest_path_modulo_small_multiple.mojo` | Mojo implementation. |
| `nim/s/shortest_path_modulo_small_multiple.nim` | Nim implementation. |
| `odin/s/shortest_path_modulo_small_multiple.odin` | Odin implementation. |
| `rust/s/shortest_path_modulo_small_multiple.rs` | Rust implementation; the raw pointer is confined to the C ABI boundary. |
| `v/s/shortest_path_modulo_small_multiple.v` | V implementation. |
| `zig/s/shortest_path_modulo_small_multiple.zig` | Zig implementation. |

The ports are source drafts. No programs, tests, checkers, or builds have been
run. The shared `i64_array_scalar` suite is not yet wired to this package.
