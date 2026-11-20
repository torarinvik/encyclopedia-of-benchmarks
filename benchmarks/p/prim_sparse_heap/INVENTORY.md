# Source inventory

| Artifact | Status | Notes |
|---|---|---|
| `README.md` | Complete | Shared MST contract, indexed sparse frontier, complexity, source attribution |
| `RIGHTS.md` | Complete | CP-Algorithms algorithm-idea provenance |
| `workload.json` | Complete | Sparse, tie, decrease-key, duplicate, boundary, and malformed cases |
| `primary_oracle.py` | Complete | Indexed binary heap with vertex positions and decrease-key |
| `independent_oracle.py` | Complete | Kruskal with disjoint-set union |
| `verify_workload.py` | Complete | Fixture/oracle consistency validation |
| `check_inventory.py` | Complete | Static ten-port and workload inventory checker |
| `benchmarks/verify_prim_sparse_heap.py` | Complete source | Dedicated all-language verifier; `i64_array_scalar` runner/verifier dispatch is integrated; not run |
| C port | Complete | `c/p/prim_sparse_heap.c` |
| C3 port | Complete | `c3/p/prim_sparse_heap.c3` |
| C++ port | Complete | `cpp/p/prim_sparse_heap.cpp` |
| Elisa port | Complete | `elisa/p/prim_sparse_heap.elisa`; fixed arrays behind the scalar ABI boundary |
| Mojo port | Complete | `mojo/p/prim_sparse_heap.mojo`; fixed `InlineArray` workspace |
| Nim port | Complete | `nim/p/prim_sparse_heap.nim` |
| Odin port | Complete | `odin/p/prim_sparse_heap.odin` |
| Rust port | Complete | `rust/p/prim_sparse_heap.rs` |
| V port | Complete | `v/p/prim_sparse_heap.v` |
| Zig port | Complete | `zig/p/prim_sparse_heap.zig` |
