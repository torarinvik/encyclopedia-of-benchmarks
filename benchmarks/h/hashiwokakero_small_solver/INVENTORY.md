# Package inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Contract, tie/crossing rules, method, complexity, and native port map |
| `RIGHTS.md` | Title-only discovery and clean-room provenance note |
| `RESERVATION.md` | Shared exact contract and implementation reservation |
| `workload.json` | Input/output bounds, source roles, and bounded scalar fixtures |
| `primary_oracle.py` | Residual-degree constrained search with feasibility pruning |
| `independent_oracle.py` | Lexicographic complete-vector exhaustive reference |
| `verify_workload.py` | Static fixture framing and two-reference reconciliation |
| `INVENTORY.json` | Machine-readable artifact and native source inventory |
| `check_inventory.py` | Static source/artifact inventory helper |
| `benchmarks/run_i64_array_scalar.py` | Scalar workload registration and primary-reference validation |
| `benchmarks/verify_i64_array_scalar.py` | Independent-reference verifier registration |

| Language | Repository source |
|---|---|
| C | `c/h/hashiwokakero_small_solver.c` |
| C3 | `c3/h/hashiwokakero_small_solver.c3` |
| C++ | `cpp/h/hashiwokakero_small_solver.cpp` |
| Elisa | `elisa/h/hashiwokakero_small_solver.elisa` |
| Mojo | `mojo/h/hashiwokakero_small_solver.mojo` |
| Nim | `nim/h/hashiwokakero_small_solver.nim` |
| Odin | `odin/h/hashiwokakero_small_solver.odin` |
| Rust | `rust/h/hashiwokakero_small_solver.rs` |
| V | `v/h/hashiwokakero_small_solver.v` |
| Zig | `zig/h/hashiwokakero_small_solver.zig` |

All ports share the endpoint-pair edge order, `0<1<2` lexicographic tie rule,
strict interior crossing rule, and all-islands connectivity requirement.
No native source or package checker has been executed.
