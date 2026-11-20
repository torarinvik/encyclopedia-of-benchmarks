# Package inventory

Candidate: `suffix_tray_pattern_query`, Chapter 422 / Cole–Kopelowitz–
Lewenstein suffix tray §3.1–3.3.

The primary builds a bounded compact suffix tree, marks σ-nodes, replaces
intervening non-σ child groups with suffix intervals, creates the source's
branching-node alphabet map and unary-node separator, then performs hybrid
query traversal with LCP-aware interval search. The independent reference
sorts all finite suffixes and tests them directly. The supplied bounded
suffix-tree/suffix-array adapters do not claim the paper's asymptotic
construction bounds.

| Language | Source | Static review |
|---|---|---|
| C | `c/s/suffix_tray_pattern_query.c` | Static source review complete |
| C3 | `c3/s/suffix_tray_pattern_query.c3` | Static source review complete |
| C++ | `cpp/s/suffix_tray_pattern_query.cpp` | Static source review complete |
| Elisa | `elisa/s/suffix_tray_pattern_query.elisa` | Static source review complete |
| Mojo | `mojo/s/suffix_tray_pattern_query.mojo` | Static source review complete |
| Nim | `nim/s/suffix_tray_pattern_query.nim` | Static source review complete |
| Odin | `odin/s/suffix_tray_pattern_query.odin` | Static source review complete |
| Rust | `rust/s/suffix_tray_pattern_query.rs` | Static source review complete |
| V | `v/s/suffix_tray_pattern_query.v` | Static source review complete |
| Zig | `zig/s/suffix_tray_pattern_query.zig` | Static source review complete |

`check_inventory.py` and `verify_workload.py` are static source helpers. They
have not been run. Byte-suite, independent-verifier, catalog, and Chapter 422
crosswalk registration are integrated; no executable checks were run.
