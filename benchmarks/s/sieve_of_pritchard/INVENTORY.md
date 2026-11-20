# Package inventory

- Algorithm: `sieve_of_pritchard`
- ABI: `i64_array_scalar`
- Input: `[N]`, exactly one signed 64-bit word, `2 <= N <= 1024`
- Result: `pi(N)` as a signed 64-bit scalar; malformed input returns `-1`
- Workspace cap: 9,216 bytes (two 1,026-entry i32 link arrays use 8,208 bytes)
- Primary reference: `primary_oracle.py`, array-linked dynamic wheel
- Independent reference: `independent_oracle.py`, direct trial division
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Shared suite/catalog registration: complete in `i64_array_scalar`
