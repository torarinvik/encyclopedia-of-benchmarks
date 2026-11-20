# Static package inventory

- Benchmark: `routh_hurwitz_stability_predicate`
- ABI: `i64_array_scalar`
- Input: `[degree, descending integer coefficients]`
- Degree: 1 through 4
- Coefficients: `[-3,3]`, with positive leading coefficient in `[1,3]`
- Result: 1 for strict left-half-plane stability, 0 for valid non-strict or unstable cases, -1 for invalid input
- Native arithmetic: exact fraction-free Routh rows; maximum scaled entry/intermediate 729
- Native workspace allowance: 1,024 bytes
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Primary reference: rational Routh-table recurrence
- Independent reference: Hurwitz leading-principal determinant expansion
- Workload helper: `verify_workload.py` reconciles every fixture against both references
- Inventory helper: `check_inventory.py` checks paths and static metadata without invoking native code
- Shared `i64_array_scalar` runner, verifier, README, and catalog integration:
  complete
- Execution status: source-only edits; no programs, tests, helpers, builds, or compilers were run
