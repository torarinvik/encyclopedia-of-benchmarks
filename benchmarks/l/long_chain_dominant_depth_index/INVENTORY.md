# Static inventory

Algorithm symbol: `long_chain_dominant_depth_index`  
ABI: `i64_array_bytes_output`  
Valid input: `[n,parent[1..n-1]]`, `1 <= n <= 64`, parent-before-child IDs.  
Result: `8*n` bytes containing the smallest dominant depth for each vertex.  
Errors: `-1` for invalid input, `-2` for null or insufficient output; errors
write no bytes.  
Output cap: 512 bytes. Workspace cap: 8,192 bytes. The widest native state has
eight fixed arrays of 64 signed 64-bit words (4,096 bytes); the remaining
4,096 bytes are reserved for scalar locals, alignment, and ABI bookkeeping.

| Language | Source |
|---|---|
| C | `c/l/long_chain_dominant_depth_index.c` |
| C3 | `c3/l/long_chain_dominant_depth_index.c3` |
| C++ | `cpp/l/long_chain_dominant_depth_index.cpp` |
| Elisa | `elisa/l/long_chain_dominant_depth_index.elisa` |
| Mojo | `mojo/l/long_chain_dominant_depth_index.mojo` |
| Nim | `nim/l/long_chain_dominant_depth_index.nim` |
| Odin | `odin/l/long_chain_dominant_depth_index.odin` |
| Rust | `rust/l/long_chain_dominant_depth_index.rs` |
| V | `v/l/long_chain_dominant_depth_index.v` |
| Zig | `zig/l/long_chain_dominant_depth_index.zig` |

Primary reference: `primary_oracle.py`, long-chain DP with shared per-chain
state storage. Independent reference: `independent_oracle.py`, repeated
subtree traversal and distance histograms. Workload and expected bytes are
pinned in `workload.json`. Static inventory source: `check_inventory.py`.
The `i64_array_bytes_output` runner and verifier plus CATALOG registration are
integrated; no programs, tests, scripts, checkers, builds, compilers, profilers,
or benchmarks were run.
