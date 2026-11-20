# Package inventory

- Package: `hilbert_curve_index_encode`
- ABI: `i64_array_bytes_output`
- Method: iterative Butz coordinate-to-distance mapping in two dimensions
- Input: `[order,x,y]`, `1<=order<=8`, coordinates in `[0,2^order)`
- Valid / parseable frame: 3 / 4 signed-i64 words
- Output: one little-endian signed-i64 Hilbert index, 8 bytes
- Native scratch: 0 bytes beyond scalar state and caller output
- References: iterative bitwise primary and recursive quadrant reference
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Source: Butz, [DOI 10.1109/T-C.1971.223258](https://doi.org/10.1109/T-C.1971.223258)

Ten language source paths are enumerated in `INVENTORY.json`. The Elisa port
uses bounded input and output views internally and confines ABI references to
its exported entry point. The package is registered in the shared byte-output
runner and verifier. No port or helper has been run.
