# Static inventory

Contract and bounded profile: `README.md`.
Provenance and reuse boundary: `RIGHTS.md`.
Fixture corpus: `workload.json`.
Primary interval reference: `primary_oracle.py`.
Independent exhaustive-mask reference: `independent_oracle.py`.
Language ports, all exporting `negafibonacci_representation`:

- `c/n/negafibonacci_representation.c`
- `c3/n/negafibonacci_representation.c3`
- `cpp/n/negafibonacci_representation.cpp`
- `elisa/n/negafibonacci_representation.elisa`
- `mojo/n/negafibonacci_representation.mojo`
- `nim/n/negafibonacci_representation.nim`
- `odin/n/negafibonacci_representation.odin`
- `rust/n/negafibonacci_representation.rs`
- `v/n/negafibonacci_representation.v`
- `zig/n/negafibonacci_representation.zig`

Shared suite registration: `benchmarks/run_i64_array_bytes_output.py` and
`benchmarks/verify_i64_array_bytes_output.py`. Root catalogs: `CATALOG.md`,
`README.md`, and `benchmarks/ALGORITHM_EXPANSION_COVERAGE.md`. No programs,
tests, scripts, checkers, builds, compilers, profilers, or benchmarks have
been run.
