# Package inventory

- ABI: `i64_array_scalar`; symbol: `cherry_pickup_ii`.
- Primary reference: `primary_oracle.py` (rolling two-column-pair DP).
- Independent reference: `independent_oracle.py` (exhaustive paired-path recursion).
- Workload: `workload.json`; maximum valid frame 38 words, parser limit 39.
- Provenance: official LeetCode 1463 description; clean-room code and fixtures.
- Static inventory entry point: `check_inventory.py:static_issues`.
- Ten ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
