# Package inventory

Algorithm: `weniger_pochhammer_partial_sum_transform`  
ABI: `i64_array_bytes_output`  
Input: `[n,k,a0,...,a_(n+k+1)]`, `n=0..8`, `k=3..4`, 7–16 valid words and 17 parseable words  
Output: canonical exact rational pair, 16 bytes  
Workspace: 0 native scratch bytes  
Primary: product-cleared integer Pochhammer weights  
Independent: direct exact-Fraction evaluation  
Source: NIST DLMF §3.9(v), Eqs. 3.9.13 and 3.9.16

## Files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`, `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`
- `c/w/weniger_pochhammer_partial_sum_transform.c`
- `c3/w/weniger_pochhammer_partial_sum_transform.c3`
- `cpp/w/weniger_pochhammer_partial_sum_transform.cpp`
- `elisa/w/weniger_pochhammer_partial_sum_transform.elisa`
- `mojo/w/weniger_pochhammer_partial_sum_transform.mojo`
- `nim/w/weniger_pochhammer_partial_sum_transform.nim`
- `odin/w/weniger_pochhammer_partial_sum_transform.odin`
- `rust/w/weniger_pochhammer_partial_sum_transform.rs`
- `v/w/weniger_pochhammer_partial_sum_transform.v`
- `zig/w/weniger_pochhammer_partial_sum_transform.zig`

The package is registered in the `i64_array_bytes_output` runner and verifier
and listed in the shared catalog. No programs, tests, helpers, builds,
compilers, or benchmarks were run.
