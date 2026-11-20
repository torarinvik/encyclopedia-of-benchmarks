# Package inventory

- Package: `barycentric_lagrange_evaluation`
- ABI: `i64_array_scalar`
- Input: `[N,x_0..x_(N-1),y_0..y_(N-1),q]`, `1<=N<=8`
- Valid / parseable frame: 18 / 19 signed-i64 words
- Output: scalar polynomial value in `F_998244353`, invalid input `-1`
- Native workspace: 128 bytes, including eight field weights
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Sources: [DLMF §3.3(i), Eq. 3.3.1](https://dlmf.nist.gov/3.3.i#E1),
  [weight definition Eq. 3.3.3_1](https://dlmf.nist.gov/3.3.i#E3_1)

All ten native paths are enumerated in `INVENTORY.json`. Elisa uses bounded
views internally with FFI pointer handling confined to the export boundary.
The package is registered in the shared scalar runner and verifier, the root
catalog, and the expansion coverage ledger. No checker, script, test, or
executable has been run.
