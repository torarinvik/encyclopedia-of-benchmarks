# Package inventory

- Package: `continued_fraction_forward_series_recurrence`
- ABI: `i64_array_bytes_output`
- Profile: Eq. 3.10.15 forward-series recurrence over `F_998244353`
- Input: `[N,a0,...,a_(N-1)]`, `2<=N<=9`, canonical field residues
- Valid / parseable frame: 10 / 11 signed-i64 words
- Output: `[N,S1,...,SN]`, little-endian signed-i64 bytes, maximum 80 bytes
- Native scratch: 0 bytes beyond scalar recurrence state and caller output
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Source: [NIST DLMF §3.10(iii), Eq. 3.10.15](https://dlmf.nist.gov/3.10#E15)

Ten native ports are listed in `INVENTORY.json`. The Elisa entry uses bounded
views internally and confines pointer handling to the exported ABI boundary.
The package is registered in the shared byte-output runner and verifier. The
ports and static artifacts have not been executed.
