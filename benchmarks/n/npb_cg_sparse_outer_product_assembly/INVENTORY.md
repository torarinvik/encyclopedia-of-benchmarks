# Package inventory

This package contains its matrix assembly references, ten language ports, and
the `verify_workload.py` static inventory checker.

The output is a binary64 vector with integral-valued structural fields followed
by the coalesced matrix values. Structural values are exactly representable;
the workload and verifier pin `1e-12` absolute and relative tolerances.

| Artifact | Path |
|---|---|
| Machine-readable workload | `workload.json` |
| Machine-readable inventory | `INVENTORY.json` |
| Primary ordered-COO oracle | `primary_oracle.py` |
| Independent dense-accumulator oracle | `independent_oracle.py` |
| Static package inventory | `verify_workload.py` |
| Rights and provenance | `RIGHTS.md` |
| C | `../../../c/n/npb_cg_sparse_outer_product_assembly.c` |
| C3 | `../../../c3/n/npb_cg_sparse_outer_product_assembly.c3` |
| C++ | `../../../cpp/n/npb_cg_sparse_outer_product_assembly.cpp` |
| Elisa | `../../../elisa/n/npb_cg_sparse_outer_product_assembly.elisa` |
| Mojo | `../../../mojo/n/npb_cg_sparse_outer_product_assembly.mojo` |
| Nim | `../../../nim/n/npb_cg_sparse_outer_product_assembly.nim` |
| Odin | `../../../odin/n/npb_cg_sparse_outer_product_assembly.odin` |
| Rust | `../../../rust/n/npb_cg_sparse_outer_product_assembly.rs` |
| V | `../../../v/n/npb_cg_sparse_outer_product_assembly.v` |
| Zig | `../../../zig/n/npb_cg_sparse_outer_product_assembly.zig` |
