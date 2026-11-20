# Static inventory

| Component | Location |
|---|---|
| Contract, source, and duplicate rationale | `README.md` |
| Rights and clean-room provenance | `RIGHTS.md` |
| Bounded deterministic replay cases | `workload.json` |
| Matrix-inverse primary reference | `primary_oracle.py` -> `benchmarks/tutte_matrix_randomized_perfect_matching_oracle.py` |
| Cofactor-expansion independent reference | `independent_oracle.py` -> `benchmarks/tutte_matrix_randomized_perfect_matching_verifier_oracle.py` |
| Static fixture/reference reconciler | `verify_workload.py` |
| Static port/artifact inventory | `check_inventory.py` |
| Machine-readable paths and bounds | `inventory.json` |
| Ten language ports | Paths listed in `README.md` and `inventory.json` |

The metadata helpers are source-only and have not been run.
