# Package inventory

Algorithm: `random_3sat_cl_bucket_heuristic`  
ABI: `i64_array_bytes_output`  
Source family: Encyclopedia of Algorithms, Chapter 423; Kaporis–Kirousis–Lalas
CL heuristic.
Suite registration: shared `i64_array_bytes_output` runner and verifier.

| Artifact | Role |
|---|---|
| `primary_oracle.py` | Mutable residual-formula reference |
| `independent_oracle.py` | Immutable-formula reference with separately rebuilt counters |
| `workload.json` | Bounded fixtures and ABI edge cases |
| `README.md` | Contract, source notes, bounds, and language map |
| `RIGHTS.md` | Clean-room provenance and rights note |
| `check_inventory.py` | Static package completeness metadata |
| `verify_workload.py` | Source-authored fixture/reference reconciler, not run |
| C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig source paths | Native benchmark ports |

The inventory records source presence only. No executable checks have been
run.
