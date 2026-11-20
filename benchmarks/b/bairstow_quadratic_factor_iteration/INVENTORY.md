# Package inventory

- Package: `bairstow_quadratic_factor_iteration`
- ABI: `i64_array_bytes_output`
- Status: integrated with the shared runner, verifier, and catalog
- Profile: DLMF Bairstow q/r recurrence over `F_998244353`, fixed 1–4 steps
- Input: `[N,a_0..a_N,s_0,t_0,K]`, `3<=N<=8`
- Valid / parseable frame: 13 / 14 signed-i64 words
- Output: `[K+1,s_0,t_0,...,s_K,t_K]`, maximum 88 bytes
- Native workspace: 512 bytes for coefficient, recurrence, trace, and scalar storage
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Sources: [DLMF §3.8(iv), Eq. 3.8.10](https://dlmf.nist.gov/3.8.iv#E10),
  [Eq. 3.8.11](https://dlmf.nist.gov/3.8.iv#E11)

The finite-field version is an algebraic recurrence trace and carries no claim
about real-root convergence. All ten native paths are listed in
`INVENTORY.json`; Elisa should retain bounded input/output views internally.
No helper or executable has been run.
