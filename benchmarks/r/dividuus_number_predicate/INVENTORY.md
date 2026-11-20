# Package inventory

Algorithm: `dividuus_number_predicate`  
ABI: `i64_array_scalar`  
Function symbol: `dividuus_number_predicate`

The package contains a numeric digit-scan primary reference, an independent string-digit/congruence reference, and `workload.json` with published positive cases, zero-divisor behavior, boundary inputs, and malformed frames. `README.md` and `RIGHTS.md` record contract and provenance. `check_inventory.py` and `verify_workload.py` provide static package review helpers.

Ten native language ports are listed in `INVENTORY.json` and linked from the README. The exact input is `[n]`, `1<=n<=100000`; output is 1 or 0, invalid input is -1. Zero digit product or zero multiplicative digital root yields false. Native workspace is capped at 256 bytes; all digit-derived intermediate values fit signed i64.
