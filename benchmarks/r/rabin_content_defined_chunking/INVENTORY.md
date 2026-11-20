# Implementation inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Bounded profile, rolling recurrence, complexity, and source distinctions. |
| `RIGHTS.md` | Clean-room provenance for the algorithm description. |
| `workload.json` | Valid, malformed, capacity, output-null, and input-null fixtures. |
| `primary_oracle.py` | Incremental GF(2) fingerprint with outgoing-byte removal before append. |
| `independent_oracle.py` | Per-window polynomial reduction, independent of the rolling update. |
| `check_inventory.py` | Static source, metadata, link, and dual-reference fixture inspection; not run. |
| `c/r/rabin_content_defined_chunking.c` | C port. |
| `c3/r/rabin_content_defined_chunking.c3` | C3 port. |
| `cpp/r/rabin_content_defined_chunking.cpp` | C++ port. |
| `elisa/r/rabin_content_defined_chunking.elisa` | Elisa port using bounded views and fixed arrays internally. |
| `mojo/r/rabin_content_defined_chunking.mojo` | Mojo port. |
| `nim/r/rabin_content_defined_chunking.nim` | Nim port. |
| `odin/r/rabin_content_defined_chunking.odin` | Odin port. |
| `rust/r/rabin_content_defined_chunking.rs` | Rust port; raw pointers are limited to the C ABI boundary. |
| `v/r/rabin_content_defined_chunking.v` | V port. |
| `zig/r/rabin_content_defined_chunking.zig` | Zig port. |

No compiler, program, test, or checker has been run.
