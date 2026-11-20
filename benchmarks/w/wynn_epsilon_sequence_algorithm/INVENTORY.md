# Package inventory

Algorithm: `wynn_epsilon_sequence_algorithm`  
ABI: `float64_slice_io`  
Registration: runner, verifier, and catalog integrated  
Input: `[N,K,samples...]`, 7–12 valid values; 13 parseable values  
Output: `[status,value]` pairs for even epsilon rows; at most 36 float64 values  
Workspace: 2,048 bytes; output staging capacity: 36 float64 elements  
Primary: binary64 epsilon tableau recurrence  
Independent: DLMF Hankel determinant ratio for stable finite even entries plus operational-status replay; rounded tableau fallback if determinant cancellation exceeds published tolerance  
Independent determinant scale: numerator magnitude `<2^41`; scaled denominator magnitude `<2^44` for the bounded input range.  
Singular rule: signed zero denominator, marked dependency, or nonfinite denominator/reciprocal/result produces `[1,0]` and propagates  
Tolerance: absolute `1e-9`, relative `1e-12`
Primary complexity: `O(NK)` time and space. Independent reference complexity:
`O(N²K + NK(K+1)!)` time and `O(NK+K³)` space.

## Files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`, `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`
- `c/w/wynn_epsilon_sequence_algorithm.c`
- `c3/w/wynn_epsilon_sequence_algorithm.c3`
- `cpp/w/wynn_epsilon_sequence_algorithm.cpp`
- `elisa/w/wynn_epsilon_sequence_algorithm.elisa`
- `mojo/w/wynn_epsilon_sequence_algorithm.mojo`
- `nim/w/wynn_epsilon_sequence_algorithm.nim`
- `odin/w/wynn_epsilon_sequence_algorithm.odin`
- `rust/w/wynn_epsilon_sequence_algorithm.rs`
- `v/w/wynn_epsilon_sequence_algorithm.v`
- `zig/w/wynn_epsilon_sequence_algorithm.zig`

The suite recorder and verifier register this package under
`float64_slice_io`; [`CATALOG.md`](../../../CATALOG.md) lists it with the
NIST DLMF recurrence source.
