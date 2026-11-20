# Static package inventory

- Benchmark: `squfof_semiprime_factor`
- ABI: `i64_array_scalar`
- Contract: `[N, forward_cap, reverse_cap]`, fixed multiplier one, even-index square-form checks
- Number bound: odd `N` in `3..1,000,000,000,000`; each cap is `0..256`
- Native workspace allowance: 512 bytes; no native heap scratch
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Primary reference: streaming continued-fraction P/Q recurrence and reverse walk
- Independent reference: table-driven `(m,d,a_n)` continued fraction with denominator invariants
- Workload helper: `verify_workload.py` compares pinned values and both references; authored but not invoked
- Static inventory helper: `check_inventory.py`; authored but not invoked
- Shared suite/catalog integration: `i64_array_scalar` runner/verifier, README, and CATALOG are registered
- Execution status: source edits and static reads only; no programs, tests, scripts, helpers, builds, or compilers were run

## Native paths

- `c/s/squfof_semiprime_factor.c`
- `c3/s/squfof_semiprime_factor.c3`
- `cpp/s/squfof_semiprime_factor.cpp`
- `elisa/s/squfof_semiprime_factor.elisa`
- `mojo/s/squfof_semiprime_factor.mojo`
- `nim/s/squfof_semiprime_factor.nim`
- `odin/s/squfof_semiprime_factor.odin`
- `rust/s/squfof_semiprime_factor.rs`
- `v/s/squfof_semiprime_factor.v`
- `zig/s/squfof_semiprime_factor.zig`
