# Package inventory

The `minimum_bounded_s_t_flow` package contains:

- `README.md` — bounded input/output contract, method profile, complexity,
  workspace bound, and language map.
- `RIGHTS.md` — CP-Algorithms method attribution and reuse terms.
- `workload.json` — hand-specified valid, infeasible, boundary, and malformed
  scalar cases.
- `primary_oracle.py` — lower-bound reduction, Edmonds–Karp feasibility, and
  binary search.
- `independent_oracle.py` — exhaustive edge-flow enumeration.
- `verify_workload.py` — static workload and reference consistency review.
- `check_inventory.py` — static package and ten-port inventory review.
- One native source per supported language: C, C3, C++, Elisa, Mojo, Nim,
  Odin, Rust, V, and Zig.

The workload uses the `i64_array_scalar` ABI and includes independent expected
results in every case. The maximum valid input contains 36 signed-i64 words;
the parseable-frame cap is 37 words. The package is registered with the
`i64_array_scalar` runner and verifier, README, catalog, and shared coverage
ledger. No project code or validation helper was executed.
