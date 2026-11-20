# Static inventory

| Component | Location |
|---|---|
| Contract, source attribution, duplicate rationale | `README.md` |
| Clean-room provenance | `RIGHTS.md` |
| Bounded cases and ABI metadata | `workload.json` |
| Modified-KMP primary reference | `primary_oracle.py` -> `benchmarks/parameterized_pattern_matching_kmp_oracle.py` |
| Independent bijection-per-window reference | `independent_oracle.py` -> `benchmarks/parameterized_pattern_matching_kmp_verifier_oracle.py` |
| Static workload/reference reconciler | `verify_workload.py` |
| Static port and artifact inventory | `check_inventory.py` |
| Machine-readable paths and bounds | `inventory.json` |
| Ten native ports | Listed in `README.md` and `inventory.json` |

The metadata helpers are source-only and have not been run.
