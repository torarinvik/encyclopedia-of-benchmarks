# Static language-port inventory

The package uses the `i64_array_bytes_output` ABI and exports
`wigderson_3_colorable_graph_coloring` from all ten suite languages. Each
implementation uses bounded fixed graph state, source-faithful `i <- i+2`
color advancement, deterministic vertex ordering, and the same byte format.

| Language | Source | Status |
| --- | --- | --- |
| C | `c/t/wigderson_3_colorable_graph_coloring.c` | Draft present; static review only |
| C3 | `c3/t/wigderson_3_colorable_graph_coloring.c3` | Draft present; static review only |
| C++ | `cpp/t/wigderson_3_colorable_graph_coloring.cpp` | Independent `std::array` implementation; static review only |
| Elisa | `elisa/t/wigderson_3_colorable_graph_coloring.elisa` | Bounded input/output views after the FFI boundary |
| Mojo | `mojo/t/wigderson_3_colorable_graph_coloring.mojo` | Draft present; static review only |
| Nim | `nim/t/wigderson_3_colorable_graph_coloring.nim` | Draft present; static review only |
| Odin | `odin/t/wigderson_3_colorable_graph_coloring.odin` | Draft present; static review only |
| Rust | `rust/t/wigderson_3_colorable_graph_coloring.rs` | Draft present; static review only |
| V | `v/t/wigderson_3_colorable_graph_coloring.v` | Draft present; static review only |
| Zig | `zig/t/wigderson_3_colorable_graph_coloring.zig` | Draft present; static review only |

`inventory.json` pins the source paths, workload fixtures, invalid-case IDs,
and maximum workspace. `check_inventory.py` compares those static records
against the workload and source files. The checker has not been run; no
programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks
were run.
