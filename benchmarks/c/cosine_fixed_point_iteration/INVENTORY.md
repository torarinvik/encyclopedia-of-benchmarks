# Static source inventory

Algorithm: bounded binary64 iteration of `x <- (cos(x) + 2) / 2`.

| Artifact | Role |
|---|---|
| `../../c/cosine_fixed_point_iteration.c` | C port |
| `../../c3/cosine_fixed_point_iteration.c3` | C3 port |
| `../../cpp/cosine_fixed_point_iteration.cpp` | C++ port |
| `../../elisa/cosine_fixed_point_iteration.elisa` | Elisa port |
| `../../mojo/cosine_fixed_point_iteration.mojo` | Mojo port |
| `../../nim/cosine_fixed_point_iteration.nim` | Nim port |
| `../../odin/cosine_fixed_point_iteration.odin` | Odin port |
| `../../rust/cosine_fixed_point_iteration.rs` | Rust port |
| `../../v/cosine_fixed_point_iteration.v` | V port |
| `../../zig/cosine_fixed_point_iteration.zig` | Zig port |
| `primary_oracle.py` | Binary64 recurrence reference |
| `independent_oracle.py` | Decimal Taylor-cosine recurrence reference |
| `workload.json` | Bounded input and output fixtures |

Every port exports `cosine_fixed_point_iteration(double initial_x, double source_n)` through the `float64_pair` ABI. The ten ports are registered with the suite runner and verifier.
