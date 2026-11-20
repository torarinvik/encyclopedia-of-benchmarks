# Package inventory

- Algorithm: `k_repetition_within_factor_copy_propagation`
- ABI: `i64_array_bytes_output`
- Sources: ten native-language ports in the repository's language directories.
- References: `primary_oracle.py` (ordered per-start records) and
  `independent_oracle.py` (full active-set scan).
- Workload: `workload.json` pins propagation, duplicate, clipping, malformed,
  null, and capacity behavior.
- Static helpers: `check_inventory.py` and `verify_workload.py`.
- Rights/provenance: `RIGHTS.md`.
- Shared runner/catalog registration is integrated in the byte-output
  runner/verifier, repository catalog, and Chapter 24 crosswalk.

