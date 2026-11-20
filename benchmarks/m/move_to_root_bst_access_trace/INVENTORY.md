# Static inventory

- Algorithm: move-to-root self-organizing binary search tree access heuristic.
- Public symbol: `move_to_root_bst_access_trace`.
- ABI: `i64_array_scalar`.
- Languages: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Input: insertion-order initial keys followed by a sequence of access keys.
- Output: access-index-weighted comparison count.
- Primary: bounded parent/left/right integer arrays and repeated single rotations.
- Independent reference: node objects with parent pointers.
- Suite registration: `benchmarks/run_i64_array_scalar.py` and
  `benchmarks/verify_i64_array_scalar.py`.
- Static review only; no programs, tests, checkers, scripts, compilers, builds,
  profilers, or benchmarks have been run.
