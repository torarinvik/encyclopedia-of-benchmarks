# Package inventory

- Package: `steed_continued_fraction_convergents`
- ABI: `i64_array_bytes_output`
- Profile: Steed Eqs. 3.10.16–3.10.17 over `F_998244353`
- Input: `[N,b0,b1,a1,...,bN,aN]`, `1<=N<=8`, canonical residues
- Valid / parseable frame: 18 / 19 signed-i64 words
- Output: `[N+1,C0,...,CN]`, little-endian signed-i64 bytes, maximum 80 bytes
- Native scratch: 0 bytes beyond scalar recurrence state and caller output
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Source: [NIST DLMF §3.10(iii), Eqs. 3.10.16–3.10.17](https://dlmf.nist.gov/3.10#E16)

All ten language ports are listed in `INVENTORY.json`. Elisa uses bounded
views internally and confines reference/pointer handling to its exported ABI
boundary. The shared `i64_array_bytes_output` runner and independent verifier
include this package. No programs, tests, or helpers have been executed.
