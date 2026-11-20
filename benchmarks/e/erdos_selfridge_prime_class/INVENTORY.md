# Static package inventory

- Benchmark: `erdos_selfridge_prime_class`
- ABI: `i64_array_scalar`
- Contract: `[prime, direction]`, direction `+1` for plus and `-1` for minus
- Prime bound: `2..100000`; class bound: 17
- Native workspace allowance: 4,096 bytes
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Primary reference: recursive factor-tree class evaluation
- Independent reference: sieve and bottom-up class table
- Workload helper: `verify_workload.py` reconciles fixtures against both references
- Shared `i64_array_scalar` runner/verifier/catalog integration: complete
- Execution status: static edits only; no programs, tests, helpers, builds, or compilers were run

