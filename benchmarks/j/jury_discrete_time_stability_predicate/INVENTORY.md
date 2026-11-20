# Static package inventory

- Benchmark: `jury_discrete_time_stability_predicate`
- ABI: `i64_array_scalar`
- Input: `[degree, descending integer coefficients]`
- Degree: 1 through 4
- Coefficients: `[-9,9]`, with nonzero leading coefficient
- Result: 1 for strict unit-disk stability, 0 for unstable or marginal, -1 for invalid input
- Primary: division-free Jury coefficient table
- Independent reference: Schur–Cohn matrix and leading-principal determinant expansion
- Maximum successive primary row magnitudes: 9, 162, 52,488, 5,509,980,288
- Independent matrix entry bound: 648; determinant order at most four
- Native workspace allowance: 1,024 bytes
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Workload helper: `verify_workload.py` reconciles fixtures against both references
- Inventory helper: `check_inventory.py` checks static paths and declared bounds
- Shared scalar suite, verifier, README, and catalog integration: complete
- Execution status: source-only edits; no programs, tests, helpers, builds, or compilers were run
