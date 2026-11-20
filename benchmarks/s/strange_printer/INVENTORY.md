# Package inventory

| Artifact | Purpose |
| --- | --- |
| `primary_oracle.py` | Cubic interval recurrence for minimum print turns. |
| `independent_oracle.py` | Breadth-first search over full blank/printed tape states. |
| `workload.json` | Bounded fixtures for repeated symbols, overwrite merges, and invalid frames. |
| `verify_workload.py` | Package-local static checks for metadata, both references, docs, and all ten ports. |
| `c/s/strange_printer.c` | C port. |
| `c3/s/strange_printer.c3` | C3 port. |
| `cpp/s/strange_printer.cpp` | C++ port. |
| `elisa/s/strange_printer.elisa` | Elisa port using a borrowed safe view inside its ABI wrapper. |
| `mojo/s/strange_printer.mojo` | Mojo port. |
| `nim/s/strange_printer.nim` | Nim port. |
| `odin/s/strange_printer.odin` | Odin port. |
| `rust/s/strange_printer.rs` | Rust port using a slice after the ABI boundary. |
| `v/s/strange_printer.v` | V port. |
| `zig/s/strange_printer.zig` | Zig port. |

The shared `i64_array_scalar` runner and verifier register this benchmark and
use the interval recurrence and BFS reference for bounded fixtures. The root
README, catalog, and coverage ledger include its source mapping.
