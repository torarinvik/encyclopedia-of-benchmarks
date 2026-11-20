# Package inventory

- Package: `miller_backward_recurrence_normalization`
- ABI: `i64_array_bytes_output`
- Profile: finite Miller backward trial and normalization over `F_998244353`
- Input: `[N,(a_n,b_n,c_n) for n=1..N,lambda_0..lambda_N]`, `1<=N<=8`
- Valid / parseable frame: 34 / 35 signed-i64 words
- Output: `[N,w_0..w_N]`, little-endian signed-i64 bytes, maximum 80 bytes
- Native workspace: 192 bytes, including ten trial entries and scalar state
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Sources: [DLMF §3.6(iii)](https://dlmf.nist.gov/3.6.iii), [Eq. 3.6.5](https://dlmf.nist.gov/3.6#E5)

All ten language ports are listed in `INVENTORY.json`. The Elisa implementation
uses bounded views internally and keeps the ABI pointer/reference handling at
the exported function boundary. The package is a finite backward recurrence
profile and does not claim asymptotic convergence. It is registered in the
shared byte-output runner and verifier. No helper has been run.
