# Package inventory

Algorithm: `aitken_delta_squared_sequence_transform`  
ABI: `i64_array_bytes_output`  
Input: `[n,s0,...,s(n-1)]`, with `2 <= n <= 64` and values in
`[-1,000,000,1,000,000]`  
Output: `n-2` reduced signed-i64 numerator/positive-denominator pairs  
Maximum valid/parseable input: 65/66 words  
Maximum output: 992 bytes  
Native auxiliary workspace: 0 fixed buffer bytes; only scalar locals are used.

## Native ports

- `c/a/aitken_delta_squared_sequence_transform.c`
- `c3/a/aitken_delta_squared_sequence_transform.c3`
- `cpp/a/aitken_delta_squared_sequence_transform.cpp`
- `elisa/a/aitken_delta_squared_sequence_transform.elisa`
- `mojo/a/aitken_delta_squared_sequence_transform.mojo`
- `nim/a/aitken_delta_squared_sequence_transform.nim`
- `odin/a/aitken_delta_squared_sequence_transform.odin`
- `rust/a/aitken_delta_squared_sequence_transform.rs`
- `v/a/aitken_delta_squared_sequence_transform.v`
- `zig/a/aitken_delta_squared_sequence_transform.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
