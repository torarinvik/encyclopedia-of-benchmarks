# Static package inventory

Package symbol: `partially_retroactive_priority_queue`  
ABI: `i64_array_bytes_output`  
Contract/workload: [`workload.json`](workload.json)
Maximum caller output buffer: 1,024 bytes. Separate conservative algorithm
working-memory bound: 16,384 bytes, excluding caller-owned output.

| Language | Source path |
| --- | --- |
| C | `c/p/partially_retroactive_priority_queue.c` |
| C3 | `c3/p/partially_retroactive_priority_queue.c3` |
| C++ | `cpp/p/partially_retroactive_priority_queue.cpp` |
| Elisa | `elisa/p/partially_retroactive_priority_queue.elisa` |
| Mojo | `mojo/p/partially_retroactive_priority_queue.mojo` |
| Nim | `nim/p/partially_retroactive_priority_queue.nim` |
| Odin | `odin/p/partially_retroactive_priority_queue.odin` |
| Rust | `rust/p/partially_retroactive_priority_queue.rs` |
| V | `v/p/partially_retroactive_priority_queue.v` |
| Zig | `zig/p/partially_retroactive_priority_queue.zig` |

References: `primary_oracle.py` uses the dynamic segment-tree bridge method;
`independent_oracle.py` rebuilds a min-heap for every updated timeline.

Static status: all ten listed paths are present, shared byte-output suite
dispatch and package workload review are integrated in source, and metadata
and fixtures have received a manual source-only review. No executable checks
or builds have been run.
