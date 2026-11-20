# Package inventory

Algorithm: `pratt_expression_evaluation`  
ABI: `i64_array_scalar`  
Input: `[token_count,(kind,payload)*token_count]`, 1–15 tokens  
Result: exact signed-i64 expression value; `INT64_MIN` on invalid input  
Valid/parseable input: 31/32 i64 words  
Maximum absolute valid result: `18^8 = 11,019,960,576`  
Maximum recursive Pratt parse depth: 16; no fixed scratch arrays.
Suite registration: shared `i64_array_scalar` runner and verifier.

## Native ports

- `c/p/pratt_expression_evaluation.c`
- `c3/p/pratt_expression_evaluation.c3`
- `cpp/p/pratt_expression_evaluation.cpp`
- `elisa/p/pratt_expression_evaluation.elisa`
- `mojo/p/pratt_expression_evaluation.mojo`
- `nim/p/pratt_expression_evaluation.nim`
- `odin/p/pratt_expression_evaluation.odin`
- `rust/p/pratt_expression_evaluation.rs`
- `v/p/pratt_expression_evaluation.v`
- `zig/p/pratt_expression_evaluation.zig`

## Package files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

No programs, tests, scripts, helpers/checkers, builds, compilers, profilers,
or benchmarks were run.
