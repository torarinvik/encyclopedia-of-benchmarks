# Static package inventory

- `workload.json` declares the bounded `sort_call` workload and semantic
  fixtures.
- `primary_oracle.py` is a bottom-up mergesort reference.
- `independent_oracle.py` uses Python's built-in ordering as a second fixture
  reference.
- `verify_workload.py` checks source inventory, package docs, and both oracle
  outputs; it has not been run.
- Ten source ports are listed in `verify_workload.py`, one per supported
  language folder.
- `RIGHTS.md` records the DADS and linked-source-index provenance.
- `benchmarks/verify_jsort.py` provides the repository sort-checker workflow;
  it has not been run.
