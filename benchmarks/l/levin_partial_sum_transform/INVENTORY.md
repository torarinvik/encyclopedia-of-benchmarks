# Package inventory

Algorithm: `levin_partial_sum_transform`  
ABI: `i64_array_bytes_output`  
Input: `[n,k,a0,...,a_(n+k+1)]`, 5–15 valid words; 16 parseable words  
Output: one canonical exact rational pair, 16 bytes  
Workspace: 0 native scratch bytes  
Primary: product-cleared integer weights and scalar accumulators  
Independent: direct exact-Fraction evaluation of DLMF's weighted formula  
Zero final denominator: malformed result `-1`, before output capacity  
Primary signed bound: `|numerator|<=1,679,616`, `|denominator|<=46,656`

## Files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`, `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`
- `c/l/levin_partial_sum_transform.c`
- `c3/l/levin_partial_sum_transform.c3`
- `cpp/l/levin_partial_sum_transform.cpp`
- `elisa/l/levin_partial_sum_transform.elisa`
- `mojo/l/levin_partial_sum_transform.mojo`
- `nim/l/levin_partial_sum_transform.nim`
- `odin/l/levin_partial_sum_transform.odin`
- `rust/l/levin_partial_sum_transform.rs`
- `v/l/levin_partial_sum_transform.v`
- `zig/l/levin_partial_sum_transform.zig`

The package is registered in the `i64_array_bytes_output` runner and verifier
and listed in the shared catalog. No programs, tests, helpers, builds,
compilers, or benchmarks were run.
