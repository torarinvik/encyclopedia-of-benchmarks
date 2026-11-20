# Package inventory

Algorithm: `wolstenholme_numbers`  
ABI: `i64_array_scalar`  
Function symbol: `wolstenholme_numbers`

The package contains two independently structured references (`primary_oracle.py` uses reduced-rational recurrence; `independent_oracle.py` uses a common LCM denominator), bounded fixtures in `workload.json`, provenance in `README.md` and `RIGHTS.md`, and the static helpers `check_inventory.py` and `verify_workload.py`.

Ten clean-room language ports are listed in `INVENTORY.json` and the package README. Native workspace is capped at 256 bytes. Maximum valid input length is one i64 word; maximum parseable input length is two words. Invalid input returns `-1`; valid results are signed i64 values in the range 1 through 86364397717734821. The package is registered in the shared `i64_array_scalar` runner and verifier; neither has been run.
