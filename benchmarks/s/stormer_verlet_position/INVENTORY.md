# Static inventory

Algorithm profile: `stormer_verlet_position` (`i64_array_bytes_output`)

| Language | File | Exported symbol |
|---|---|---|
| C | `c/s/stormer_verlet_position.c` | `stormer_verlet_position` |
| C3 | `c3/s/stormer_verlet_position.c3` | `stormer_verlet_position` |
| C++ | `cpp/s/stormer_verlet_position.cpp` | `stormer_verlet_position` |
| Elisa | `elisa/s/stormer_verlet_position.elisa` | `stormer_verlet_position` |
| Mojo | `mojo/s/stormer_verlet_position.mojo` | `stormer_verlet_position` |
| Nim | `nim/s/stormer_verlet_position.nim` | `stormer_verlet_position` |
| Odin | `odin/s/stormer_verlet_position.odin` | `stormer_verlet_position` |
| Rust | `rust/s/stormer_verlet_position.rs` | `stormer_verlet_position` |
| V | `v/s/stormer_verlet_position.v` | `stormer_verlet_position` |
| Zig | `zig/s/stormer_verlet_position.zig` | `stormer_verlet_position` |

Each implementation validates the full input before output-capacity checks,
computes at most 32 positions, encodes signed 64-bit outputs little-endian in a
256-byte local staging buffer, then copies only after validation succeeds.
