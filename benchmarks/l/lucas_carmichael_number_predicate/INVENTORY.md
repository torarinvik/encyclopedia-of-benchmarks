# Package inventory

Algorithm: `lucas_carmichael_number_predicate`  
ABI: `i64_array_scalar`  
Function symbol: `lucas_carmichael_number_predicate`

The package includes two differently structured references: residual trial
factorization in `primary_oracle.py`, and a fixed prime sieve with original-input
divisibility checks in `independent_oracle.py`. `workload.json` contains hand-pinned
valid, invalid, and framing cases. `README.md` records semantics and provenance;
`RIGHTS.md` documents clean-room authorship. `verify_workload.py` and
`check_inventory.py` are static helpers and have not been run.

Ten native ports are listed in `INVENTORY.json` and the README. The profile accepts
one signed-i64 value from 1 through 1,000,000, returns 0 or 1, and returns -1 for
invalid framing or values. The declared native workspace allowance is 128 bytes.
The `i64_array_scalar` runner and verifier dispatch this package; catalog and
source coverage records identify the distinct `p + 1` divisibility criterion.
