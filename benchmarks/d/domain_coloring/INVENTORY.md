# Static inventory

Algorithm profile: `domain_coloring` (`i64_array_bytes_output`)

| Language | File | Exported symbol |
|---|---|---|
| C | `c/d/domain_coloring.c` | `domain_coloring` |
| C3 | `c3/d/domain_coloring.c3` | `domain_coloring` |
| C++ | `cpp/d/domain_coloring.cpp` | `domain_coloring` |
| Elisa | `elisa/d/domain_coloring.elisa` | `domain_coloring` |
| Mojo | `mojo/d/domain_coloring.mojo` | `domain_coloring` |
| Nim | `nim/d/domain_coloring.nim` | `domain_coloring` |
| Odin | `odin/d/domain_coloring.odin` | `domain_coloring` |
| Rust | `rust/d/domain_coloring.rs` | `domain_coloring` |
| V | `v/d/domain_coloring.v` | `domain_coloring` |
| Zig | `zig/d/domain_coloring.zig` | `domain_coloring` |

Each port validates the six-word frame and bounded grid, stages at most 768
RGB bytes, and copies them to the caller only after input and output-capacity
validation succeed. The static workspace bound is 768 bytes plus scalar
temporaries; no dynamic allocation is required.
