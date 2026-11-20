# Static inventory

- Algorithm: `gpsr_perimeter_recovery_trace`
- ABI: `i64_array_bytes_output`
- Chapter/source: *Encyclopedia of Algorithms*, Chapter 352; Karp–Kung GPSR,
  MobiCom 2000, §§2.2 and 2.4, DOI 10.1145/345910.345953.
- Native implementations: ten supported languages.
- Input bound: 56 valid words, 57 parseable words; `n<=8`, `m<=18`.
- Output bound: 112 signed 64-bit words / 896 bytes.
- Workspace cap: 8,192 bytes.
- Suite registration: `i64_array_bytes_output` runner and verifier.
- Primary reference stores counterclockwise rotations; the independent reference
  computes the next rotation on demand and uses rational intersections.
- Workload includes a strict-progress face crossing, a no-crossing recovery,
  invalid crossing geometry, malformed trailing data, null input/output, and
  short capacity.

## Native paths

- `c/g/gpsr_perimeter_recovery_trace.c`
- `c3/g/gpsr_perimeter_recovery_trace.c3`
- `cpp/g/gpsr_perimeter_recovery_trace.cpp`
- `elisa/g/gpsr_perimeter_recovery_trace.elisa`
- `mojo/g/gpsr_perimeter_recovery_trace.mojo`
- `nim/g/gpsr_perimeter_recovery_trace.nim`
- `odin/g/gpsr_perimeter_recovery_trace.odin`
- `rust/g/gpsr_perimeter_recovery_trace.rs`
- `v/g/gpsr_perimeter_recovery_trace.v`
- `zig/g/gpsr_perimeter_recovery_trace.zig`

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

The inventory and workload helpers are source artifacts and have not been run.
