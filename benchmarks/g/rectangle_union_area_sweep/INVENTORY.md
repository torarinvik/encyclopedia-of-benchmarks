# Static package inventory

- `workload.json` fixes the bounded `i64_array_scalar` input and semantic
  fixtures.
- `primary_oracle.py` computes x-slabs and merges active y-intervals without
  a coverage tree.
- `independent_oracle.py` enumerates integer unit cells for small-coordinate
  cases.
- `verify_workload.py` checks workload metadata, source inventory, documentation,
  and fixtures; it has not been run.
- The package maximum fixed-array workspace is 13,824 bytes: 13,312 bytes of
  core arrays plus the Mojo port's 512-byte traversal stack.
- The shared `i64_array_scalar` runner and verifier register this package. The
  verifier uses the unit-cell oracle on small coordinates and the slab oracle
  for fixtures outside that reference's bounded grid.
- Ten language source ports are listed in `verify_workload.py`.
- Local inventory comparison found the two-rectangle formula in
  `rectangle_union_area` and triangle vertical decomposition, but no general
  set-of-rectangles Bentley/Klee sweep with a y-coverage tree.
- No programs, tests, scripts, checkers, builds, compilers, profilers, or
  benchmarks were run.
