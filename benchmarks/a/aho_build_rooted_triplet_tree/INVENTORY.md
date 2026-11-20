# Static inventory

Algorithm: `aho_build_rooted_triplet_tree`  
ABI: `i64_array_bytes_output`  
Maximum valid/parseable input: 317/318 i64 words  
Maximum output: 112 bytes  
Workspace: 8,192 bytes

| Language | Port |
|---|---|
| C | `c/a/aho_build_rooted_triplet_tree.c` |
| C3 | `c3/a/aho_build_rooted_triplet_tree.c3` |
| C++ | `cpp/a/aho_build_rooted_triplet_tree.cpp` |
| Elisa | `elisa/a/aho_build_rooted_triplet_tree.elisa` |
| Mojo | `mojo/a/aho_build_rooted_triplet_tree.mojo` |
| Nim | `nim/a/aho_build_rooted_triplet_tree.nim` |
| Odin | `odin/a/aho_build_rooted_triplet_tree.odin` |
| Rust | `rust/a/aho_build_rooted_triplet_tree.rs` |
| V | `v/a/aho_build_rooted_triplet_tree.v` |
| Zig | `zig/a/aho_build_rooted_triplet_tree.zig` |

Package references: `primary_oracle.py`, `independent_oracle.py`.  
Package workload: `workload.json`; static contract review helper:
`verify_workload.py`.  
Package metadata: `README.md`, `RIGHTS.md`, `SOURCE_CROSSWALK.md`,
`INVENTORY.json`, and `check_inventory.py`.

Sources: Aho et al., DOI `10.1137/0210030`; Jansson and Sung, Encyclopedia of
Algorithms Chapter 92, DOI `10.1007/978-1-4939-2864-4_92`.
