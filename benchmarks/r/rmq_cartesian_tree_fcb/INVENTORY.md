# Package inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Bounded RMQ contract, method distinction, complexity, source, and ports |
| `RIGHTS.md` | Source license and clean-room provenance |
| `workload.json` | Hand-derived success, bounds, malformed-frame, and output-capacity fixtures |
| `primary_oracle.py` | Cartesian-tree + Euler-tour FCB reference |
| `independent_oracle.py` | Direct scan of every requested array interval |
| `check_inventory.py` | Static artifact and ten-port inventory; no execution |
| `c/r/rmq_cartesian_tree_fcb.c` | C port |
| `c3/r/rmq_cartesian_tree_fcb.c3` | C3 port |
| `cpp/r/rmq_cartesian_tree_fcb.cpp` | C++ port |
| `elisa/r/rmq_cartesian_tree_fcb.elisa` | Elisa bounded-view port |
| `mojo/r/rmq_cartesian_tree_fcb.mojo` | Mojo port |
| `nim/r/rmq_cartesian_tree_fcb.nim` | Nim port |
| `odin/r/rmq_cartesian_tree_fcb.odin` | Odin port |
| `rust/r/rmq_cartesian_tree_fcb.rs` | Rust port |
| `v/r/rmq_cartesian_tree_fcb.v` | V port |
| `zig/r/rmq_cartesian_tree_fcb.zig` | Zig port |

Inventory status is source-only. No port, workload, checker, compiler, or
benchmark has been run.
