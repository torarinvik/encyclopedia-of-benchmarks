# Implementation inventory

| Artifact | Purpose / status |
| --- | --- |
| `README.md` | Bounded online rectangle-count contract and complexity. |
| `RIGHTS.md` | OI Wiki attribution and clean-room provenance. |
| `workload.json` | Valid, boundary, malformed, and null fixtures. |
| `primary_oracle.py` | Outer Fenwick tree over x-blocks, with inner Fenwick trees over y. |
| `independent_oracle.py` | Direct scan of all current points for each query. |
| `verify_workload.py` | Static metadata, fixture, documentation, and port inventory review; not run. |
| `c/f/fenwick_tree_in_block_array_rectangle_count.c` | C implementation. |
| `c3/f/fenwick_tree_in_block_array_rectangle_count.c3` | C3 implementation. |
| `cpp/f/fenwick_tree_in_block_array_rectangle_count.cpp` | C++ implementation. |
| `elisa/f/fenwick_tree_in_block_array_rectangle_count.elisa` | Elisa implementation with a slice-based internal helper. |
| `mojo/f/fenwick_tree_in_block_array_rectangle_count.mojo` | Mojo implementation. |
| `nim/f/fenwick_tree_in_block_array_rectangle_count.nim` | Nim implementation. |
| `odin/f/fenwick_tree_in_block_array_rectangle_count.odin` | Odin implementation. |
| `rust/f/fenwick_tree_in_block_array_rectangle_count.rs` | Rust implementation; raw input access is limited to the C ABI boundary. |
| `v/f/fenwick_tree_in_block_array_rectangle_count.v` | V implementation. |
| `zig/f/fenwick_tree_in_block_array_rectangle_count.zig` | Zig implementation. |

All ports are source drafts. No programs, tests, checkers, or builds have been
run. Shared `i64_array_scalar` suite wiring remains separate.
