# Implementation inventory

| Artifact | Purpose / status |
|---|---|
| `README.md` | Bounded update and range-k-th contract, complexity, and method distinction. |
| `RIGHTS.md` | OI Wiki attribution and clean-room provenance. |
| `workload.json` | Valid, boundary, malformed, and null fixtures. |
| `primary_oracle.py` | Outer Fenwick tree whose nodes own mutable weighted value segment trees. |
| `independent_oracle.py` | Direct replacement replay and per-query sort reference. |
| `check_inventory.py` | Static package, source, link, and dual-reference fixture review; not run. |
| `c/f/fenwick_weighted_segment_tree_range_kth.c` | C implementation. |
| `c3/f/fenwick_weighted_segment_tree_range_kth.c3` | C3 implementation. |
| `cpp/f/fenwick_weighted_segment_tree_range_kth.cpp` | C++ implementation. |
| `elisa/f/fenwick_weighted_segment_tree_range_kth.elisa` | Elisa implementation using safe slices internally; raw pointer only at ABI boundary. |
| `mojo/f/fenwick_weighted_segment_tree_range_kth.mojo` | Mojo implementation. |
| `nim/f/fenwick_weighted_segment_tree_range_kth.nim` | Nim implementation. |
| `odin/f/fenwick_weighted_segment_tree_range_kth.odin` | Odin implementation. |
| `rust/f/fenwick_weighted_segment_tree_range_kth.rs` | Rust implementation; raw input access is limited to the C ABI boundary. |
| `v/f/fenwick_weighted_segment_tree_range_kth.v` | V implementation. |
| `zig/f/fenwick_weighted_segment_tree_range_kth.zig` | Zig implementation. |

No shared suite files were changed. Source ports are uncompiled drafts; no
programs, tests, checkers, builds, or benchmarks have been run.
