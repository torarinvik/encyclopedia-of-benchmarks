# Static inventory

- Algorithm: deterministic Lovasz-toggle defective two-coloring trace.
- Public symbol: `lovasz_toggle_defective_coloring_trace`.
- ABI: `i64_array_scalar`.
- Languages: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Input: vertex count, red/blue same-color degree limits, initial red mask,
  and canonical undirected edges.
- Output: toggle count packed with the final red mask.
- Primary: fixed adjacency bit masks and lowest-index bad-vertex scans.
- Independent reference: adjacency sets and a boolean color vector.
- Suite registration: `benchmarks/run_i64_array_scalar.py` and
  `benchmarks/verify_i64_array_scalar.py`.
- Source review only; no programs, tests, checkers, scripts, compilers, builds,
  profilers, or benchmarks have been run.
