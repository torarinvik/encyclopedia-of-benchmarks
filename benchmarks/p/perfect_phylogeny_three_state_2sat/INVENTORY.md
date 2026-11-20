# Package inventory

The package is a bounded clean-room implementation of the three-state
perfect-phylogeny 2-SAT reduction, extended explicitly to characters that
observe one or two of the three allowed state labels.

| Artifact | Role |
|---|---|
| `primary_oracle.py` | Expanded state-columns, 2-CNF clauses, implication SCC feasibility oracle |
| `independent_oracle.py` | Enumerates omitted states, enforces the missing-state extension independently, and checks compatibility directly |
| `workload.json` | Valid, invalid, zero-character, obstruction, and maximum-size fixtures |
| `SOURCE_CROSSWALK.md` | Separates Chapter 288 context from Gusfield–Wu's operational reduction |
| `verify_workload.py` | Static workload/reference consistency helper |
| `check_inventory.py` | Static package/port/provenance inventory helper |
| `RIGHTS.md` | Attribution and clean-room provenance |

| Language | Port |
|---|---|
| C | `c/p/perfect_phylogeny_three_state_2sat.c` |
| C3 | `c3/p/perfect_phylogeny_three_state_2sat.c3` |
| C++ | `cpp/p/perfect_phylogeny_three_state_2sat.cpp` |
| Elisa | `elisa/p/perfect_phylogeny_three_state_2sat.elisa` |
| Mojo | `mojo/p/perfect_phylogeny_three_state_2sat.mojo` |
| Nim | `nim/p/perfect_phylogeny_three_state_2sat.nim` |
| Odin | `odin/p/perfect_phylogeny_three_state_2sat.odin` |
| Rust | `rust/p/perfect_phylogeny_three_state_2sat.rs` |
| V | `v/p/perfect_phylogeny_three_state_2sat.v` |
| Zig | `zig/p/perfect_phylogeny_three_state_2sat.zig` |

Each character may observe one to three labels. Two-state characters force
their missing state-column false; constant characters are unconstrained. The
maximum valid frame is 66 signed 64-bit words; the maximum parseable frame is
67 words. The 2-SAT formula has at most 284 clauses and 568 implication arcs.
The scalar result is `0` or `1`, with `-1` for invalid input.
The declared native workspace ceiling is 8,192 bytes. The package is
registered in the `i64_array_scalar` runner/verifier and the root catalog.
