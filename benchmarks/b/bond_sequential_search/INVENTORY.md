# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Composite OR-mask scan with exact candidate checks. |
| `independent_oracle.py` | Two independent direct scans for first-match indices. |
| `workload.json` | Bounded fixtures for matches, false candidates, absent keys, and invalid frames. |
| `verify_workload.py` | Static checks for package metadata, references, docs, and all ten ports. |
| `benchmarks/run_i64_array_scalar.py` and `benchmarks/verify_i64_array_scalar.py` | Scalar suite registration and workload/reference routing. |
| `c/b/bond_sequential_search.c` | C port. |
| `c3/b/bond_sequential_search.c3` | C3 port. |
| `cpp/b/bond_sequential_search.cpp` | C++ port. |
| `elisa/b/bond_sequential_search.elisa` | Elisa port using a borrowed view internally. |
| `mojo/b/bond_sequential_search.mojo` | Mojo port. |
| `nim/b/bond_sequential_search.nim` | Nim port. |
| `odin/b/bond_sequential_search.odin` | Odin port. |
| `rust/b/bond_sequential_search.rs` | Rust port using a slice after the ABI boundary. |
| `v/b/bond_sequential_search.v` | V port. |
| `zig/b/bond_sequential_search.zig` | Zig port. |
