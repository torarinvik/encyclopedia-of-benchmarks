# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Bounding-box precedence graph and Kahn topological elimination. |
| `independent_oracle.py` | Exhaustively simulate every order of present colors on the fixed bounding boxes. |
| `workload.json` | Bounded rectangular grids, paint dependencies, cycles, and invalid framing. |
| `verify_workload.py` | Package-local static checks for metadata, both references, and ten exported ports. |
| `c/s/strange_printer_ii.c` | C port. |
| `c3/s/strange_printer_ii.c3` | C3 port. |
| `cpp/s/strange_printer_ii.cpp` | C++ port. |
| `elisa/s/strange_printer_ii.elisa` | Elisa port with a safe borrowed view behind the ABI boundary. |
| `mojo/s/strange_printer_ii.mojo` | Mojo port. |
| `nim/s/strange_printer_ii.nim` | Nim port. |
| `odin/s/strange_printer_ii.odin` | Odin port. |
| `rust/s/strange_printer_ii.rs` | Rust port using a safe slice after the ABI boundary. |
| `v/s/strange_printer_ii.v` | V port. |
| `zig/s/strange_printer_ii.zig` | Zig port. |

The package uses the `i64_array_scalar` suite. Shared README/CATALOG/coverage
registration is maintained separately.
