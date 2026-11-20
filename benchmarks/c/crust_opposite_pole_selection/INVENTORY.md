# Package inventory

Algorithm: `crust_opposite_pole_selection`  
ABI: `i64_array_bytes_output`  
Bounds: at most 8 sample rows, 8 candidate vertices per row, 225 valid input
words, 136 output bytes, and 1,024 bytes of fixed workspace.

| Item | Path |
|---|---|
| Primary reference | `primary_oracle.py` |
| Independent brute-force reference | `independent_oracle.py` |
| Workload and fixtures | `workload.json` |
| Workload verifier | `verify_workload.py` |
| Static inventory checker | `check_inventory.py` |
| Rights and provenance | `RIGHTS.md` |
| Contract and source crosswalk | `README.md` |
| Machine-readable inventory | `INVENTORY.json` |

Ten language ports are listed in `INVENTORY.json`. Shared suite/catalog
registration is handled by the root agent after package review.
