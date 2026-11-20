# Package inventory

Algorithm: `euler_alternating_series_transform`  
ABI: `i64_array_bytes_output`  
Input: `[n,a0,...,a(n-1)]`, with `1 <= n <= 16` and values in
`[-1,000,000,1,000,000]`  
Output: one reduced signed-i64 numerator/positive-denominator pair  
Maximum valid/parseable input: 17/18 words  
Maximum output: 16 bytes  
Native auxiliary workspace: 0 fixed buffer bytes; only scalar locals are used.

## Native ports

- `c/e/euler_alternating_series_transform.c`
- `c3/e/euler_alternating_series_transform.c3`
- `cpp/e/euler_alternating_series_transform.cpp`
- `elisa/e/euler_alternating_series_transform.elisa`
- `mojo/e/euler_alternating_series_transform.mojo`
- `nim/e/euler_alternating_series_transform.nim`
- `odin/e/euler_alternating_series_transform.odin`
- `rust/e/euler_alternating_series_transform.rs`
- `v/e/euler_alternating_series_transform.v`
- `zig/e/euler_alternating_series_transform.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
