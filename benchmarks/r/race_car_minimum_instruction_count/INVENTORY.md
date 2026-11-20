# Package inventory

Algorithm: `race_car_minimum_instruction_count`  
ABI: `i64_array_scalar`  
Input: `[target]`, `0..127`  
Output: minimum command count, with the proven upper bound `0..379`  
Maximum valid/parseable input: 1/2 i64 words  
Native fixed workspace: 512 bytes (`i32[128]`).

## Native ports

- `c/r/race_car_minimum_instruction_count.c`
- `c3/r/race_car_minimum_instruction_count.c3`
- `cpp/r/race_car_minimum_instruction_count.cpp`
- `elisa/r/race_car_minimum_instruction_count.elisa`
- `mojo/r/race_car_minimum_instruction_count.mojo`
- `nim/r/race_car_minimum_instruction_count.nim`
- `odin/r/race_car_minimum_instruction_count.odin`
- `rust/r/race_car_minimum_instruction_count.rs`
- `v/r/race_car_minimum_instruction_count.v`
- `zig/r/race_car_minimum_instruction_count.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, helpers/checkers, builds, compilers, profilers,
or benchmarks were run.

The package is registered in the shared `i64_array_scalar` runner and verifier,
the root catalog, and the expansion coverage ledger.
