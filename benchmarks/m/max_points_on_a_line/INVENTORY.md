# Package inventory

- ABI: `i64_array_scalar`; symbol: `max_points_on_a_line`.
- Primary reference: `primary_oracle.py` (per-anchor normalized direction buckets).
- Independent reference: `independent_oracle.py` (pair-defined lines and exact cross products).
- Workload: `workload.json`; maximum valid frame 33 words, parser limit 34.
- Provenance: LeetCode 149 and CP-Algorithms integer line representation;
  clean-room implementations and fixtures.
- Static inventory entry point: `check_inventory.py:static_issues`.
- Ten source ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
