# Static package inventory

- Algorithm: `minkowski_question_mark_rational`
- ABI: `i64_array_bytes_output`
- Native implementations: ten supported language ports.
- Input: `[p,q]`, `0<=p<=q<=1,000,000`; regular-CF quotient sum at most 60.
- Output: reduced dyadic numerator/exponent pair, always 16 bytes.
- Workspace: 128 bytes of scalar state; no heap or variable-sized scratch arrays.
- References: continued-fraction alternating sum and Stern-Brocot bisection.
- Workload: exact rational fixtures, bounds, malformed frames, null/short output.

## Native paths

- `c/m/minkowski_question_mark_rational.c`
- `c3/m/minkowski_question_mark_rational.c3`
- `cpp/m/minkowski_question_mark_rational.cpp`
- `elisa/m/minkowski_question_mark_rational.elisa`
- `mojo/m/minkowski_question_mark_rational.mojo`
- `nim/m/minkowski_question_mark_rational.nim`
- `odin/m/minkowski_question_mark_rational.odin`
- `rust/m/minkowski_question_mark_rational.rs`
- `v/m/minkowski_question_mark_rational.v`
- `zig/m/minkowski_question_mark_rational.zig`

## Package files

- `__init__.py`
- `README.md`
- `RIGHTS.md`
- `INVENTORY.md`
- `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`
- `independent_oracle.py`
- `verify_workload.py`
- `check_inventory.py`

Static helpers are source artifacts and have not been executed.
