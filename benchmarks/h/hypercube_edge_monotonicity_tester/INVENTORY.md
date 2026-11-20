# Package inventory

`inventory.json` lists the package references, fixtures, and ten language
ports. The truth table and fixed random-choice tape are supplied in the input
frame, so each port uses bounded local state and writes only the 24-byte result
after validating the complete input and output capacity.

| Role | File |
|---|---|
| Primary source-ordered reference | `primary_oracle.py` |
| Independent full violation-trace reference | `independent_oracle.py` |
| Fixture/reference verifier | `verify_workload.py` |
| Static package inventory checker | `check_inventory.py` |
| Workload and pinned fixtures | `workload.json` |
| Rights and provenance | `RIGHTS.md` |
| C | `c/h/hypercube_edge_monotonicity_tester.c` |
| C3 | `c3/h/hypercube_edge_monotonicity_tester.c3` |
| C++ | `cpp/h/hypercube_edge_monotonicity_tester.cpp` |
| Elisa | `elisa/h/hypercube_edge_monotonicity_tester.elisa` |
| Mojo | `mojo/h/hypercube_edge_monotonicity_tester.mojo` |
| Nim | `nim/h/hypercube_edge_monotonicity_tester.nim` |
| Odin | `odin/h/hypercube_edge_monotonicity_tester.odin` |
| Rust | `rust/h/hypercube_edge_monotonicity_tester.rs` |
| V | `v/h/hypercube_edge_monotonicity_tester.v` |
| Zig | `zig/h/hypercube_edge_monotonicity_tester.zig` |

Paths are relative to the repository root. No checker, test, build, or
benchmark was run during drafting.
