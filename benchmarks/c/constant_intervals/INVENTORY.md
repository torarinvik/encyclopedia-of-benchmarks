# Static inventory

Package: `constant_intervals`

- ABI: `i64_array_bytes_output`, symbol `constant_intervals`.
- Contract: `[n, step, offset, divisor]`; `0<=n<=256`,
  `step,offset<=65535`, `1<=divisor<=65535`.
- Output: `k` triples `(lo, hi, f(lo))`, each little-endian signed i32;
  result is `k`; maximum capacity/workspace 3072 bytes.
- Primary reference: recursive endpoint-pruned partition.
- Independent references: threshold-equation run-boundary calculation and
  direct function scan.
- Workload and provenance: `workload.json`, `README.md`, `RIGHTS.md`.
- Static artifact checker: `check_inventory.py`.
- Ports:
  - `c/c/constant_intervals.c`
  - `c3/c/constant_intervals.c3`
  - `cpp/c/constant_intervals.cpp`
  - `elisa/c/constant_intervals.elisa`
  - `mojo/c/constant_intervals.mojo`
  - `nim/c/constant_intervals.nim`
  - `odin/c/constant_intervals.odin`
  - `rust/c/constant_intervals.rs`
  - `v/c/constant_intervals.v`
  - `zig/c/constant_intervals.zig`
- Shared runner, verifier, root README/catalog, and expansion ledger are
  recorded in the root inventory after integration.

Shared suite registration: `benchmarks/run_i64_array_bytes_output.py` and
`benchmarks/verify_i64_array_bytes_output.py`. Root catalogs: `CATALOG.md`,
`README.md`, and `benchmarks/ALGORITHM_EXPANSION_COVERAGE.md`. This inventory
is a static file/contract record. No port, oracle, fixture, checker, build,
or benchmark was executed.
