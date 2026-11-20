# Package inventory

The benchmark uses the `i64_array_bytes_output` ABI and the symbol
`steiner_tree_mehlhorn_voronoi_mst`.

| Artifact | Path |
|---|---|
| Primary reference | `primary_oracle.py` |
| Independent reference | `independent_oracle.py` |
| Pinned workload | `workload.json` |
| Static workload reconciler | `verify_workload.py` |
| Static source inventory checker | `check_inventory.py` |
| Provenance and rights | `RIGHTS.md` |
| Contract and source notes | `README.md` |
| Suite inventory | `inventory.json` |
| Supplemental source inventory | `INVENTORY.json` |

Suite registration is present in `benchmarks/run_i64_array_bytes_output.py`
and `benchmarks/verify_i64_array_bytes_output.py`; catalog and root README
entries are integrated. All ten ports were reconciled statically against the
package contract. No programs, helpers, checks, compilers, or benchmarks were
run.

| Language | Source |
|---|---|
| C | `c/s/steiner_tree_mehlhorn_voronoi_mst.c` |
| C3 | `c3/s/steiner_tree_mehlhorn_voronoi_mst.c3` |
| C++ | `cpp/s/steiner_tree_mehlhorn_voronoi_mst.cpp` |
| Elisa | `elisa/s/steiner_tree_mehlhorn_voronoi_mst.elisa` |
| Mojo | `mojo/s/steiner_tree_mehlhorn_voronoi_mst.mojo` |
| Nim | `nim/s/steiner_tree_mehlhorn_voronoi_mst.nim` |
| Odin | `odin/s/steiner_tree_mehlhorn_voronoi_mst.odin` |
| Rust | `rust/s/steiner_tree_mehlhorn_voronoi_mst.rs` |
| V | `v/s/steiner_tree_mehlhorn_voronoi_mst.v` |
| Zig | `zig/s/steiner_tree_mehlhorn_voronoi_mst.zig` |

Inventory records source presence only. No compiler, helper, program, test, or
benchmark was run.
