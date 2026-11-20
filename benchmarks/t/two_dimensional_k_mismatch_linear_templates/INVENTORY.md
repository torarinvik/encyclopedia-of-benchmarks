# Package inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Algorithm, bounds, ABI, source citations, and language list |
| `RIGHTS.md` | Clean-room provenance and attribution |
| `workload.json` | Bounded byte-output fixtures and capacity/error cases |
| `primary_oracle.py` | Static-grid two-witness filter and bounded verification |
| `independent_oracle.py` | Exhaustive Hamming-distance reference |
| `check_inventory.py` | Static package and ten-port inventory |
| `c/t/two_dimensional_k_mismatch_linear_templates.c` | C port |
| `c3/t/two_dimensional_k_mismatch_linear_templates.c3` | C3 port |
| `cpp/t/two_dimensional_k_mismatch_linear_templates.cpp` | C++ port |
| `elisa/t/two_dimensional_k_mismatch_linear_templates.elisa` | Elisa port |
| `mojo/t/two_dimensional_k_mismatch_linear_templates.mojo` | Mojo port |
| `nim/t/two_dimensional_k_mismatch_linear_templates.nim` | Nim port |
| `odin/t/two_dimensional_k_mismatch_linear_templates.odin` | Odin port |
| `rust/t/two_dimensional_k_mismatch_linear_templates.rs` | Rust port |
| `v/t/two_dimensional_k_mismatch_linear_templates.v` | V port |
| `zig/t/two_dimensional_k_mismatch_linear_templates.zig` | Zig port |

The bounded workload targets the `i64_array_bytes_output` ABI. Shared suite
registration is intentionally handled outside this package.
