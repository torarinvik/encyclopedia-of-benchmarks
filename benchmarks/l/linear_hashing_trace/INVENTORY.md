# Static inventory

- Algorithm: incremental bucket-split linear hashing.
- Public symbol: `linear_hashing_trace`.
- ABI: `i64_array_scalar`.
- Languages: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Input: `[Q,(opcode,key)*Q]`, `0<=Q<=63`, keys `[-1024,1023]`.
- Output: packed success bits, or `-1` for malformed input.
- Primary: fixed-array separate-chaining table, split pointer, one-bucket rehash.
- Independent reference: flat-list set model.
- Suite registration: `benchmarks/run_i64_array_scalar.py` and
  `benchmarks/verify_i64_array_scalar.py`.
- Static review only; no programs, tests, checkers, scripts, compilers, builds,
  profilers, or benchmarks have been run.
