# Static package inventory

- Benchmark id: `weight-balanced-leaf-tree-order-statistics-v1`
- ABI and exported symbol: `i64_array_scalar`, `weight_balanced_leaf_tree_order_statistics`
- Ten ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Primary reference: fixed-node merge-based WBLT with `alpha=1/4`
- Independent reference: sorted multiset with direct rank and neighbor operations
- Workload: `workload.json` (13 cases)
- Rights and provenance: `RIGHTS.md`
- User-facing contract: `README.md`
- Source: [OI Wiki WBLT](https://oi-wiki.org/ds/wblt/), algorithm description only
- Suite: `benchmarks/run_i64_array_scalar.py` and `benchmarks/verify_i64_array_scalar.py`

The package was edited statically. No program, helper, test, checker, build,
compiler, profiler, or benchmark was run.
