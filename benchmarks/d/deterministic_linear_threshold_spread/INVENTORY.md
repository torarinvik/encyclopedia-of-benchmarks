# Package inventory

`INVENTORY.json` records the references, workload, rights metadata, and ten
language ports. The graph and thresholds are read from the caller's bounded
frame. Ports use bounded local frontier, activation-round, and accumulated
weight state; output is written only after full validation and capacity
checking.

| Role | File |
|---|---|
| Primary queue reference | `primary_oracle.py` |
| Independent repeated-scan reference | `independent_oracle.py` |
| Workload and fixtures | `workload.json` |
| Rights and provenance | `RIGHTS.md` |
| Static source inventory | `check_inventory.py` |
| Fixture/reference metadata review | `verify_workload.py` |
| C | `c/deterministic_linear_threshold_spread.c` |
| C3 | `c3/deterministic_linear_threshold_spread.c3` |
| C++ | `cpp/deterministic_linear_threshold_spread.cpp` |
| Elisa | `elisa/deterministic_linear_threshold_spread.elisa` |
| Mojo | `mojo/deterministic_linear_threshold_spread.mojo` |
| Nim | `nim/deterministic_linear_threshold_spread.nim` |
| Odin | `odin/deterministic_linear_threshold_spread.odin` |
| Rust | `rust/deterministic_linear_threshold_spread.rs` |
| V | `v/deterministic_linear_threshold_spread.v` |
| Zig | `zig/deterministic_linear_threshold_spread.zig` |

Repository-relative source paths are recorded in `INVENTORY.json`. All work
was source-only; no checkers, programs, builds, tests, or benchmarks were run.
