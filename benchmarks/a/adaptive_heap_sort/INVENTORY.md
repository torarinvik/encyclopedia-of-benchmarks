# Static package inventory

- `workload.json` defines the bounded signed-i64 `sort_call` contract and
  semantic fixtures.
- `primary_oracle.py` is an independent bottom-up mergesort reference.
- `independent_oracle.py` uses Python's built-in ordering as a second
  fixture reference.
- `verify_workload.py` checks source inventory, package docs, workload
  metadata, and fixture outputs; it has not been run.
- `benchmarks/verify_adaptive_heap_sort.py` contains the custom `sort_call`
  corpus/checker workflow; it has not been run.
- Ten language source ports are listed in `verify_workload.py`.
- `RIGHTS.md` records that DADS uses “RBST” wording while the detailed cited
  LP93 method is the deterministic Cartesian-tree frontier heap.
- Local inventory comparison found no matching implementation in ordinary
  `heap_sort`, `heap_sort_2`, `weak_heapsort`, `smooth_sort`,
  `adaptive_merge_sort`, `cartesian_tree`, `tree_sort`, `patience_sort`, or
  `min_heap_bulk_extract_sorted`.
- No programs, tests, scripts, checkers, builds, compilers, profilers, or
  benchmarks were run.
