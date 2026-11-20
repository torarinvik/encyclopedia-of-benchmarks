# Static inventory

The package-local [`verify_workload.py`](verify_workload.py) reads metadata,
primary and independent references, workload fixtures, and all ten source
ports. It checks bounds, required fixtures, output bytes, and exported symbols
without compilation or program execution.

| Language | Source |
|---|---|
| C | `c/g/scc_condensation_dag.c` |
| C3 | `c3/g/scc_condensation_dag.c3` |
| C++ | `cpp/g/scc_condensation_dag.cpp` |
| Elisa | `elisa/g/scc_condensation_dag.elisa` |
| Mojo | `mojo/g/scc_condensation_dag.mojo` |
| Nim | `nim/g/scc_condensation_dag.nim` |
| Odin | `odin/g/scc_condensation_dag.odin` |
| Rust | `rust/g/scc_condensation_dag.rs` |
| V | `v/g/scc_condensation_dag.v` |
| Zig | `zig/g/scc_condensation_dag.zig` |
