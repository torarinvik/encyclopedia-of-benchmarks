# Implementation inventory

| Artifact | Purpose |
|---|---|
| `README.md` | Bounded ordered-merging contract, exact predicate, complexity, and source links. |
| `RIGHTS.md` | Research attribution and clean-room provenance. |
| `workload.json` | Metadata and hand-derived valid, malformed, and output-error fixtures. |
| `primary_oracle.py` | Sorted grid edges and union-by-size disjoint-set forest. |
| `independent_oracle.py` | Flat labels, explicit member scans, and exact rational mean comparisons. |
| `check_inventory.py` | Static metadata, fixture, documentation-link, and ten-port source review. |
| `c/s/statistical_region_merging_table.c` | C port, fixed-difference scan with a disjoint-set forest. |
| `c3/s/statistical_region_merging_table.c3` | C3 port. |
| `cpp/s/statistical_region_merging_table.cpp` | C++ port. |
| `elisa/s/statistical_region_merging_table.elisa` | Elisa port; internal working arrays use bounded views and local fixed arrays. |
| `mojo/s/statistical_region_merging_table.mojo` | Mojo port. |
| `nim/s/statistical_region_merging_table.nim` | Nim port. |
| `odin/s/statistical_region_merging_table.odin` | Odin port. |
| `rust/s/statistical_region_merging_table.rs` | Rust port; raw pointer access is limited to the C ABI boundary. |
| `v/s/statistical_region_merging_table.v` | V port. |
| `zig/s/statistical_region_merging_table.zig` | Zig port. |

The byte-output suite has separate oracle modules and workload generation. No
program, test, suite verifier, compiler, or benchmark was run for this package.
