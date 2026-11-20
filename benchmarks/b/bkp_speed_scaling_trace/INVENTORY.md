# Static package inventory

The benchmark package contains:

- `README.md`: bounded BKP speed-rule contract and provenance.
- `RIGHTS.md`: clean-room reuse and source notes.
- `workload.json`: deterministic bounded byte-output fixtures.
- `primary_oracle.py`: exact integer cross-product implementation.
- `independent_oracle.py`: independent `Fraction`-based implementation.
- `verify_workload.py`: static artifact/fixture inventory checker (not run).
- `benchmarks/bkp_speed_scaling_trace_oracle.py`: primary suite byte wrapper.
- `benchmarks/bkp_speed_scaling_trace_verifier_oracle.py`: independent suite
  byte wrapper.
- Ten language ports are listed in the README and stored in the repository
  language roots under their `b/` directories.

No source program, workload verifier, test, build, or benchmark has been run.
