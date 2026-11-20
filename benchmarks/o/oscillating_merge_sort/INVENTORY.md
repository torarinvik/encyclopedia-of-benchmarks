# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Recursive alternating-direction run construction and backward-read merge simulation. |
| `independent_oracle.py` | Built-in signed integer ordering reference. |
| `workload.json` | `sort_call` lengths, deterministic input generation, and small semantic fixtures. |
| `verify_workload.py` | Static metadata, oracle-fixture, verifier-presence, and ten-port inventory checks. |
| `benchmarks/verify_oscillating_merge_sort.py` | Dedicated source for the shared sort checker and sort runner workflow. |
| `c/o/oscillating_merge_sort.c` | C port. |
| `c3/o/oscillating_merge_sort.c3` | C3 port. |
| `cpp/o/oscillating_merge_sort.cpp` | C++ port. |
| `elisa/o/oscillating_merge_sort.elisa` | Elisa port using borrowed views for internal run buffers. |
| `mojo/o/oscillating_merge_sort.mojo` | Mojo port. |
| `nim/o/oscillating_merge_sort.nim` | Nim port. |
| `odin/o/oscillating_merge_sort.odin` | Odin port. |
| `rust/o/oscillating_merge_sort.rs` | Rust port using slices after its ABI boundary. |
| `v/o/oscillating_merge_sort.v` | V port. |
| `zig/o/oscillating_merge_sort.zig` | Zig port. |

The ABI is the in-place `sort_call` signature. Shared runner and checker code
and root catalog entries are not changed by this package.
