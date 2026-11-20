# Package inventory

| Artifact | Purpose |
|---|---|
| `workload.json` | Contract, provenance, and fixtures |
| `primary_oracle.py` | Direct row/column algorithm reference |
| `independent_oracle.py` | Codeword-map and prefix-trie reference |
| `README.md` | Contract, operation order, bounds, source notes, and port map |
| `RIGHTS.md` | Clean-room and source-license note |
| `INVENTORY.json` | Machine-readable package and source list |
| `check_inventory.py` | Static source and metadata checker |
| `verify_workload.py` | Static fixture framing and reference reconciler |

The only omitted board cells are the two holes in row zero. Their column digits are the indicators for rows one and two. The other 28 cells contain unique printable ASCII symbols. The maximum frame is 96 i64 values (97 parseable for the trailing-frame probe); output is bounded to 128 bytes. The CrypTool Book supplies method context under GFDL 1.3-or-later, but only the algorithm idea is used.

| Language | Repository source |
|---|---|
| C | `c/s/straddling_checkerboard_transducer.c` |
| C3 | `c3/s/straddling_checkerboard_transducer.c3` |
| C++ | `cpp/s/straddling_checkerboard_transducer.cpp` |
| Elisa | `elisa/s/straddling_checkerboard_transducer.elisa` |
| Mojo | `mojo/s/straddling_checkerboard_transducer.mojo` |
| Nim | `nim/s/straddling_checkerboard_transducer.nim` |
| Odin | `odin/s/straddling_checkerboard_transducer.odin` |
| Rust | `rust/s/straddling_checkerboard_transducer.rs` |
| V | `v/s/straddling_checkerboard_transducer.v` |
| Zig | `zig/s/straddling_checkerboard_transducer.zig` |

No programs, scripts, tests, checkers, builds, compilers, or benchmarks have been run for this package.
