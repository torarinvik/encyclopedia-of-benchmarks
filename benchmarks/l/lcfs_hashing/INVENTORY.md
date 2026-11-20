# Static package inventory

- `workload.json` defines the bounded `i64_array_scalar` profile and fixtures.
- `primary_oracle.py` models LCFS insertion with an iterative table.
- `independent_oracle.py` uses recursive resident displacement as a separate
  reference formulation.
- `verify_workload.py` checks the package inventory and both oracle outputs;
  it is registered as static suite metadata and is not run here.
- Ten source ports are listed in `verify_workload.py`, one per supported
  language.
- `RIGHTS.md` records the DADS provenance and clean-room scope.
