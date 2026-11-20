# Static language-port inventory

The package uses the `i64_array_bytes_output` ABI and exports
`levcopoulos_lingas_planar_geometric_spanner` in all ten suite languages. Each
port validates the supplied strict-general-position Delaunay edge set, builds
the deterministic Euclidean MST, and replays the bounded contour/stack profile.

| Language | Source | Static notes |
| --- | --- | --- |
| C | `c/l/levcopoulos_lingas_planar_geometric_spanner.c` | Fixed arrays; byte output staged before writes. |
| C3 | `c3/l/levcopoulos_lingas_planar_geometric_spanner.c3` | Fixed arrays; little-endian i64 serialization. |
| C++ | `cpp/l/levcopoulos_lingas_planar_geometric_spanner.cpp` | Independent C++ implementation using vectors, sets, and arrays. |
| Elisa | `elisa/l/levcopoulos_lingas_planar_geometric_spanner.elisa` | Bounded state arrays and output views behind the FFI boundary. |
| Mojo | `mojo/l/levcopoulos_lingas_planar_geometric_spanner.mojo` | Bounded native source draft. |
| Nim | `nim/l/levcopoulos_lingas_planar_geometric_spanner.nim` | Bounded sequences and fixed result arrays. |
| Odin | `odin/l/levcopoulos_lingas_planar_geometric_spanner.odin` | Fixed arrays and explicit little-endian output. |
| Rust | `rust/l/levcopoulos_lingas_planar_geometric_spanner.rs` | Fixed state arrays; FFI slice is formed at the export boundary. |
| V | `v/l/levcopoulos_lingas_planar_geometric_spanner.v` | Fixed state arrays and deterministic ordering. |
| Zig | `zig/l/levcopoulos_lingas_planar_geometric_spanner.zig` | Fixed state arrays and explicit byte serialization. |

[`inventory.json`](inventory.json) pins all source paths, the workload path,
and fixture IDs. [`check_inventory.py`](check_inventory.py) statically compares
those records against the source tree and both references. Primary reference:
[`primary_oracle.py`](primary_oracle.py), a directed-dart LIFO stack.
Independent reference: [`independent_oracle.py`](independent_oracle.py), a
face-event stack that scans the boundary state. The package has not been
compiled or run; no tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
