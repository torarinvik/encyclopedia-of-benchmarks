# Package inventory

Package: `discrete_interval_encoding_tree`

- ABI: `i64_array_bytes_output`
- Input: `[Q,(opcode,key)*Q]`, `Q=0..32`, key `-15..15`
- Output: one LE i64 per operation, `64*cardinality + 2*interval_nodes + present`
- Bounds: 65 valid / 66 parseable input words, 256 output bytes, 8,192 workspace bytes
- Primary reference: unbalanced BST of maximal closed integer intervals
- Independent reference: fixed-domain bitmap and maximal-run count
- Provenance: Erwig, JFP 1998, DOI 10.1017/S0956796898003116; NIST DADS
- Duplicate comparison: DIET point-set BST differs from the sorted-list half-open
  range container in update/query operations, representation, and output metric
- The local `common_interval_decomposition_tree` computes strong permutation
  intervals; it does not maintain a mutable integer point set or fuse/split runs

All ten sources and package artifacts are listed in `INVENTORY.json`.
The ten language ports are registered in the shared byte-output runner and
verifier; root README, catalog, and expansion ledger entries are present.
Static inventory/workload review is available through `check_inventory.py`
and `verify_workload.py`; neither helper has been run.
