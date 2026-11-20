# Package inventory

- Contract, source distinction, arithmetic bounds, and provenance: `README.md`.
- Rights note: `RIGHTS.md`.
- Pinned workload: `workload.json`.
- Primary Floyd–Warshall reference: `benchmarks/wulff_nilsen_distance_refinement_oracle.py`.
- Independent simple-path/on-demand-bunch reference: `benchmarks/wulff_nilsen_distance_refinement_independent_oracle.py`.
- Static workload reconciler: `verify_workload.py` (`workload_issues()`).
- Static source/artifact inventory: `check_inventory.py` (`static_issues()`, `check_inventory()`).
- Machine-readable artifact list: `inventory.json`.
- Ten language sources are listed in `README.md`.
- Shared scalar runner/verifier and catalog registration are integrated; Chapter 568 crosswalk updated.

No program, test, checker, build, compiler, profiler, or benchmark has been run
for this package.
