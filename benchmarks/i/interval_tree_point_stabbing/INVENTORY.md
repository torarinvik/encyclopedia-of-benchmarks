# Package inventory

- Algorithm: `interval_tree_point_stabbing`
- ABI: `i64_array_bytes_output`
- Contract: static balanced max-high interval tree; all closed intervals
  containing each supplied point are represented by original-ID bit masks.
- Bounds: 42 valid / 43 parseable input words; 72 output bytes; 4,096 workspace
  bytes.
- Primary reference: `primary_oracle.py`, augmented balanced-tree construction
  and pruned point traversal.
- Independent reference: `independent_oracle.py`, direct interval scans.
- Workload: `workload.json`; framing, result bytes, invalid cases, and capacity
  cases are statically described by `verify_workload.py`.
- Static file inventory: `check_inventory.py`.
- Shared suite/catalog registration: integrated in the byte-output runner,
  verifier, and root catalog/coverage records.

## Native sources

| Language | Path |
| --- | --- |
| C | `c/i/interval_tree_point_stabbing.c` |
| C3 | `c3/i/interval_tree_point_stabbing.c3` |
| C++ | `cpp/i/interval_tree_point_stabbing.cpp` |
| Elisa | `elisa/i/interval_tree_point_stabbing.elisa` |
| Mojo | `mojo/i/interval_tree_point_stabbing.mojo` |
| Nim | `nim/i/interval_tree_point_stabbing.nim` |
| Odin | `odin/i/interval_tree_point_stabbing.odin` |
| Rust | `rust/i/interval_tree_point_stabbing.rs` |
| V | `v/i/interval_tree_point_stabbing.v` |
| Zig | `zig/i/interval_tree_point_stabbing.zig` |
