# Package inventory

Algorithm: `bricks_falling_when_hit_reverse_dsu`  
ABI: `i64_array_bytes_output`  
Input: `[rows,columns,hit_count,grid..., (row,column)*hit_count]`  
Dimensions: `1..8` each; hit count: `0..16`, distinct in-bounds positions  
Initial condition: every brick is four-neighbor connected to the top row  
Output: one little-endian i64 fall count per hit  
Valid/parseable input: 99/100 words maximum  
Maximum output: 16 words / 128 bytes  
Native fixed workspace: 584 bytes (64-byte grid, two 65-element i32 DSU arrays).

## Native ports

- `c/b/bricks_falling_when_hit_reverse_dsu.c`
- `c3/b/bricks_falling_when_hit_reverse_dsu.c3`
- `cpp/b/bricks_falling_when_hit_reverse_dsu.cpp`
- `elisa/b/bricks_falling_when_hit_reverse_dsu.elisa`
- `mojo/b/bricks_falling_when_hit_reverse_dsu.mojo`
- `nim/b/bricks_falling_when_hit_reverse_dsu.nim`
- `odin/b/bricks_falling_when_hit_reverse_dsu.odin`
- `rust/b/bricks_falling_when_hit_reverse_dsu.rs`
- `v/b/bricks_falling_when_hit_reverse_dsu.v`
- `zig/b/bricks_falling_when_hit_reverse_dsu.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
