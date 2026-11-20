# Package inventory

Algorithm: `ruth_aaron_number_predicate`  
ABI: `i64_array_scalar`  
Function symbol: `ruth_aaron_number_predicate`

The package includes a trial-division primary reference and a least-prime-factor sieve reference, bounded fixtures in `workload.json`, provenance in `README.md` and `RIGHTS.md`, and static helpers `check_inventory.py` and `verify_workload.py`.

Ten clean-room language ports are listed in `INVENTORY.json` and README. The input is one signed i64 word `[n]`, `1<=n<=100000`; the return is 1 for a repeated-factor Ruth–Aaron number and 0 otherwise. Invalid input returns -1. The workspace cap is 1048576 bytes; a full native i64 least-prime-factor table through 100001 uses 800016 bytes. The package is registered in the shared `i64_array_scalar` runner and verifier; neither has been run.
