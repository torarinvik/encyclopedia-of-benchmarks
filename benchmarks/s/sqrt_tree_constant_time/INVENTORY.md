# Static inventory

Package: `sqrt_tree_constant_time`  
ABI: `i64_array_bytes_output`  
Input: `[n,q,values...,left,right...]`, `n<=64`, `q<=64`  
Output: little-endian signed 64-bit range minima  
Workspace: 8,192 bytes; maximum output: 512 bytes

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Power-of-two layer construction and O(1) bit-selected queries |
| `independent_oracle.py` | Direct scan of every requested interval |
| `workload.json` | Hand-derived outputs, maximum frame, malformed and ABI cases |
| `verify_workload.py` | Static fixture, oracle, and ten-port preflight |
| `check_inventory.py` | `static_issues()` reports missing artifacts/ports without reading the workload; `inspect_inventory()` returns inventory counts |
| `README.md` | Contract, construction layout, complexity, distinctions, source |
| `RIGHTS.md` | Clean-room provenance and source attribution |
| `c/s/sqrt_tree_constant_time.c` | C port |
| `c3/s/sqrt_tree_constant_time.c3` | C3 port |
| `cpp/s/sqrt_tree_constant_time.cpp` | C++ port |
| `elisa/s/sqrt_tree_constant_time.elisa` | Elisa port with bounded views and fixed arrays |
| `mojo/s/sqrt_tree_constant_time.mojo` | Mojo port |
| `nim/s/sqrt_tree_constant_time.nim` | Nim port |
| `odin/s/sqrt_tree_constant_time.odin` | Odin port |
| `rust/s/sqrt_tree_constant_time.rs` | Rust port |
| `v/s/sqrt_tree_constant_time.v` | V port |
| `zig/s/sqrt_tree_constant_time.zig` | Zig port |

`static_issues()` only reads package paths and port source text; it does not
load or validate workload cases. The shared byte-output suite and root
documentation remain parent-owned. No executable checks were run.
