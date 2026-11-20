# Package inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Algorithm description, contract, complexity, provenance, and port list |
| `RIGHTS.md` | Clean-room provenance and source attribution |
| `workload.json` | Bounded byte-output cases and capacity/error behavior |
| `primary_oracle.py` | Template-index candidate filter and exact candidate verification |
| `independent_oracle.py` | Direct exhaustive comparison of every text window |
| `check_inventory.py` | Static package and ten-language source inventory |
| `c/t/two_dimensional_optimal_expected_matching.c` | C port |
| `c3/t/two_dimensional_optimal_expected_matching.c3` | C3 port |
| `cpp/t/two_dimensional_optimal_expected_matching.cpp` | C++ port |
| `elisa/t/two_dimensional_optimal_expected_matching.elisa` | Elisa port using bounded views internally |
| `mojo/t/two_dimensional_optimal_expected_matching.mojo` | Mojo port |
| `nim/t/two_dimensional_optimal_expected_matching.nim` | Nim port |
| `odin/t/two_dimensional_optimal_expected_matching.odin` | Odin port |
| `rust/t/two_dimensional_optimal_expected_matching.rs` | Rust port |
| `v/t/two_dimensional_optimal_expected_matching.v` | V port |
| `zig/t/two_dimensional_optimal_expected_matching.zig` | Zig port |

The package is registered with the `i64_array_bytes_output` runner and
independent verifier. Sources have not been compiled or run.
