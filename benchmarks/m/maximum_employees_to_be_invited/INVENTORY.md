# Package inventory

- ABI: `i64_array_scalar`; symbol: `maximum_employees_to_be_invited`.
- Primary reference: `primary_oracle.py` (indegree peeling and chain DP).
- Independent reference: `independent_oracle.py` (subset/circle enumeration).
- Workload: `workload.json`; maximum valid frame 9 words, parser limit 10.
- Provenance: official LeetCode 2127 and OI Wiki functional-graph concept;
  clean-room implementation and fixtures.
- Static inventory entry point: `check_inventory.py:static_issues`.
- Ten source ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
