# Static package inventory

The package contains ten FFI ports, a primary mask-layer BFS oracle, an independent unmatched-count/backtracking oracle, a bounded workload, provenance/rights, and a package-local metadata/workload reviewer.

| Language | Source |
|---|---|
| C | `c/m/minimum_parenthesis_removal_bfs.c` |
| C3 | `c3/m/minimum_parenthesis_removal_bfs.c3` |
| C++ | `cpp/m/minimum_parenthesis_removal_bfs.cpp` |
| Elisa | `elisa/m/minimum_parenthesis_removal_bfs.elisa` |
| Mojo | `mojo/m/minimum_parenthesis_removal_bfs.mojo` |
| Nim | `nim/m/minimum_parenthesis_removal_bfs.nim` |
| Odin | `odin/m/minimum_parenthesis_removal_bfs.odin` |
| Rust | `rust/m/minimum_parenthesis_removal_bfs.rs` |
| V | `v/m/minimum_parenthesis_removal_bfs.v` |
| Zig | `zig/m/minimum_parenthesis_removal_bfs.zig` |

ABI bounds: valid input 17 words, parseable input 18 words, maximum output 4,354 bytes, workspace 8,192 bytes. Static review only; no port was compiled and no checker or workload helper was executed.
