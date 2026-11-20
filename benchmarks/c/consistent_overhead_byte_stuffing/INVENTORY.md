# Package inventory

Algorithm: `consistent_overhead_byte_stuffing`  
ABI: `i64_array_bytes_output`  
Function symbol: `consistent_overhead_byte_stuffing`

The package contains a streaming code-slot oracle and a separate zero-delimited
chunk oracle, plus bounded byte fixtures in `workload.json`. The clean-room
ports, contract, source links, and rights notes are listed in the README and
`RIGHTS.md`. `verify_workload.py` reconciles pinned outputs with both references;
`check_inventory.py` checks file and port declarations. These helpers are
source artifacts and have not been run.

All ten supported language ports are enumerated in `INVENTORY.json`. The profile
accepts a payload of 0–255 bytes, stages at most 257 encoded bytes, and declares
384 bytes of workspace. The `i64_array_bytes_output` runner and verifier dispatch
the package.
