# Package inventory

Algorithm: `set_puzzle_find_sets`  
ABI: `i64_array_bytes_output`  
Input: `[n,card0,...,card(n-1)]`, with `0 <= n <= 12`, unique codes in
`[0,80]`, and `code = d0 + 3*d1 + 9*d2 + 27*d3`  
Output: `[set_count,(i,j,k)*]`, with zero-based lexicographically ordered
triples  
Maximum valid/parseable input: 13/14 words  
Maximum output bound: 67 words / 536 bytes  
Native auxiliary workspace: 93 fixed buffer bytes.

The package is registered in the `i64_array_bytes_output` runner and verifier
and listed in the shared catalog.

## Native ports

- `c/s/set_puzzle_find_sets.c`
- `c3/s/set_puzzle_find_sets.c3`
- `cpp/s/set_puzzle_find_sets.cpp`
- `elisa/s/set_puzzle_find_sets.elisa`
- `mojo/s/set_puzzle_find_sets.mojo`
- `nim/s/set_puzzle_find_sets.nim`
- `odin/s/set_puzzle_find_sets.odin`
- `rust/s/set_puzzle_find_sets.rs`
- `v/s/set_puzzle_find_sets.v`
- `zig/s/set_puzzle_find_sets.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
