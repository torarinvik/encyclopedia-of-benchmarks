# Package inventory

| Artifact | Purpose |
|---|---|
| `workload.json` | Contract metadata, source provenance, and bounded fixtures |
| `primary_oracle.py` | Bitmask domain reference with FIFO support propagation |
| `independent_oracle.py` | Set-domain reference with repeated ordered full arc sweeps |
| `README.md` | Contract, operation ordering, method, bounds, and port map |
| `RIGHTS.md` | Clean-room and provenance note |
| `INVENTORY.json` | Machine-readable artifact and native source list |
| `check_inventory.py` | Static source/artifact inventory checker |
| `verify_workload.py` | Static fixture framing and dual-reference reconciler |

The algorithm queue is seeded with all cells once in row-major order before observation. Queue membership is deduplicated with a per-cell flag, which is cleared on pop; changed neighbors are appended only when not already queued. Later observation steps use the same rule seeded with the collapsed cell.

| Language | Repository source |
|---|---|
| C | `c/w/wave_function_collapse_simple_tiled.c` |
| C3 | `c3/w/wave_function_collapse_simple_tiled.c3` |
| C++ | `cpp/w/wave_function_collapse_simple_tiled.cpp` |
| Elisa | `elisa/w/wave_function_collapse_simple_tiled.elisa` |
| Mojo | `mojo/w/wave_function_collapse_simple_tiled.mojo` |
| Nim | `nim/w/wave_function_collapse_simple_tiled.nim` |
| Odin | `odin/w/wave_function_collapse_simple_tiled.odin` |
| Rust | `rust/w/wave_function_collapse_simple_tiled.rs` |
| V | `v/w/wave_function_collapse_simple_tiled.v` |
| Zig | `zig/w/wave_function_collapse_simple_tiled.zig` |

The workload cites the two Wave Function Collapse papers for method context and the pinned popular-task title index for discovery. The title index provides no popularity score used by this package. No scripts, tests, builds, compilers, programs, or benchmarks have been run for these edits.
