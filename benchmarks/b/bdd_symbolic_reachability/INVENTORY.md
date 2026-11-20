# Package inventory

Algorithm: `bdd_symbolic_reachability`  
ABI: `i64_array_scalar`  
Input: `[n,m,initial_mask,invariant_mask,T...]`, with `1<=n<=3`, `0<=m<=1`  
Valid frame length: `4 + 2^(2*n+m)`, at most 132 words  
Parseable frame length: at most 133 words  
Output: `(reachable_mask<<1)|violation`, invalid result `-1`  
Native workspace ceiling: 294,912 bytes
Largest fixed native array set: 218,536 raw bytes (17,000 `u8` variables; four 17,000-entry `u16` node/result arrays; 32,768 `u16` unique-table entries). Five ports omit the two transform-result arrays and use 150,536 raw bytes.
Conservative per-round node bound: 16,531, within the 17,000-node capacity
Recursive path bound: eight frames per operation, at most sixteen nested frames for existential abstraction plus apply
Binary apply: recursive Shannon expansion without an operation memo table; per-round temporary tables and allocation reset

## Native ports

- `c/b/bdd_symbolic_reachability.c`
- `cpp/b/bdd_symbolic_reachability.cpp`
- `rust/b/bdd_symbolic_reachability.rs`
- `elisa/b/bdd_symbolic_reachability.elisa`
- `c3/b/bdd_symbolic_reachability.c3`
- `nim/b/bdd_symbolic_reachability.nim`
- `odin/b/bdd_symbolic_reachability.odin`
- `v/b/bdd_symbolic_reachability.v`
- `zig/b/bdd_symbolic_reachability.zig`
- `mojo/b/bdd_symbolic_reachability.mojo`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

The source crosswalk is *Encyclopedia of Algorithms*, Chapter 416, with its
Chapter 48 ROBDD representation entry. The independent reference uses explicit
state-set iteration. All checks remain unrun to keep the machine quiet.
