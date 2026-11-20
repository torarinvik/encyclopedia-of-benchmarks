# Package inventory

Algorithm: `subtractive_prng_bentley_seeded_sequence`  
ABI: `i64_array_bytes_output`  
Input: `[seed,count]`, seed `0..999,999,999`, count `0..64`  
Output: `count` little-endian signed-i64 values beginning at `r[220]`  
Maximum valid/parseable input: 2/3 words  
Maximum output: 64 words / 512 bytes  
Native fixed workspace: 440 bytes (two arrays of 55 i32 values). A valid zero-count call returns before building the state.

## Native ports

- `c/s/subtractive_prng_bentley_seeded_sequence.c`
- `c3/s/subtractive_prng_bentley_seeded_sequence.c3`
- `cpp/s/subtractive_prng_bentley_seeded_sequence.cpp`
- `elisa/s/subtractive_prng_bentley_seeded_sequence.elisa`
- `mojo/s/subtractive_prng_bentley_seeded_sequence.mojo`
- `nim/s/subtractive_prng_bentley_seeded_sequence.nim`
- `odin/s/subtractive_prng_bentley_seeded_sequence.odin`
- `rust/s/subtractive_prng_bentley_seeded_sequence.rs`
- `v/s/subtractive_prng_bentley_seeded_sequence.v`
- `zig/s/subtractive_prng_bentley_seeded_sequence.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
