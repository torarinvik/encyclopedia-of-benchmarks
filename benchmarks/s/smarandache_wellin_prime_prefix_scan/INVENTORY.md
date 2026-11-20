# Package inventory

- Algorithm: `smarandache_wellin_prime_prefix_scan`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (streamed prime generation and bounded Miller–Rabin)
- Independent reference: `independent_oracle.py` (small sieve and square-root trial division)
- Workload: `workload.json` (zero/maximum count, pinned prime-prefix outputs, parser errors, null output, and short capacity)
- Workload reconciliation helper: `verify_workload.py` (authored only; not run)
- Static path/metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite status: registered in the `i64_array_bytes_output` runner and verifier.

The native workspace cap is 256 bytes. This includes a three-value result stage, a 24-byte serialized stage, fixed primality base/small-prime tables where materialized, and bounded scalar/index state. The largest relevant combination is under 200 bytes; caller-owned input/output buffers are excluded. The maximum output is 24 bytes. No package helper, program, native port, compiler, or test has been executed.

## Native source paths

| Language | Source |
| --- | --- |
| C | `c/s/smarandache_wellin_prime_prefix_scan.c` |
| C3 | `c3/s/smarandache_wellin_prime_prefix_scan.c3` |
| C++ | `cpp/s/smarandache_wellin_prime_prefix_scan.cpp` |
| Elisa | `elisa/s/smarandache_wellin_prime_prefix_scan.elisa` |
| Mojo | `mojo/s/smarandache_wellin_prime_prefix_scan.mojo` |
| Nim | `nim/s/smarandache_wellin_prime_prefix_scan.nim` |
| Odin | `odin/s/smarandache_wellin_prime_prefix_scan.odin` |
| Rust | `rust/s/smarandache_wellin_prime_prefix_scan.rs` |
| V | `v/s/smarandache_wellin_prime_prefix_scan.v` |
| Zig | `zig/s/smarandache_wellin_prime_prefix_scan.zig` |
