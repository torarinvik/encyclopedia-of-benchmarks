# Static package inventory

- Algorithm: `multidimensional_newton_raphson`
- ABI: `i64_array_bytes_output`
- Native implementations: ten supported language ports.
- Input: `[x0_milli,y0_milli,updates]`, coordinates `900..1500`, updates `1..8`.
- Method: binary64 coupled 2D Newton step with the full Jacobian.
- Output: two 1e-9-rounded signed i64 coordinates, little-endian, 16 bytes.
- Workspace: at most 128 bytes of native scalar state, excluding caller buffers.
- References: primary binary64 closed-form inverse and independent binary64
  Cramer solve formed from explicit Jacobian entries.
- Workload: symmetric/asymmetric starts, one/eight steps, malformed frames, and output errors.
- Suite: registered through the shared `i64_array_bytes_output` runner and verifier.

## Native paths

- `c/m/multidimensional_newton_raphson.c`
- `c3/m/multidimensional_newton_raphson.c3`
- `cpp/m/multidimensional_newton_raphson.cpp`
- `elisa/m/multidimensional_newton_raphson.elisa`
- `mojo/m/multidimensional_newton_raphson.mojo`
- `nim/m/multidimensional_newton_raphson.nim`
- `odin/m/multidimensional_newton_raphson.odin`
- `rust/m/multidimensional_newton_raphson.rs`
- `v/m/multidimensional_newton_raphson.v`
- `zig/m/multidimensional_newton_raphson.zig`

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
