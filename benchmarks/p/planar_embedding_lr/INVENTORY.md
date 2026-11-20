# Static language-port inventory

The profile uses the `i64_array_bytes_output` ABI. Each source exports
`planar_embedding_lr` and writes a status byte plus an optional cyclic-neighbor
certificate. All ports are expected to implement the bounded LR DFS/conflict
pair procedure and the same deterministic tie rules.

| Language | Source | Status |
| --- | --- | --- |
| C | `c/p/planar_embedding_lr.c` | Draft present; static review only |
| C3 | `c3/p/planar_embedding_lr.c3` | Draft present; static review only |
| C++ | `cpp/p/planar_embedding_lr.cpp` | Independent fixed-array `std::array` implementation; static review only |
| Elisa | `elisa/p/planar_embedding_lr.elisa` | Draft present; bounded views behind the FFI boundary |
| Mojo | `mojo/p/planar_embedding_lr.mojo` | Draft present; static review only |
| Nim | `nim/p/planar_embedding_lr.nim` | Draft present; static review only |
| Odin | `odin/p/planar_embedding_lr.odin` | Draft present; static review only |
| Rust | `rust/p/planar_embedding_lr.rs` | Draft present; static review only |
| V | `v/p/planar_embedding_lr.v` | Draft present; static review only |
| Zig | `zig/p/planar_embedding_lr.zig` | Draft present; static review only |

The static inventory metadata pins all ten source paths, the valid fixture
inputs, their status bytes and return lengths, and the invalid fixture IDs.
The inventory reviewer checks those records against `workload.json`, then
checks that each listed source exists and contains the required exported
symbol. It also confirms that the C++ path owns an implementation and does not
source-include the C kernel. These drafts have not been compiled or executed.
No program, test, script, checker, build, compiler, profiler, or benchmark has
been run.
