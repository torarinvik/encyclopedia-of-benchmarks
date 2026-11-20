# Package inventory

- Package: `lentz_continued_fraction_convergents`
- ABI: `i64_array_bytes_output`
- Status: integrated with the shared runner, verifier, and catalog
- Input: `[N,b0,(a1,b1),...,(aN,bN)]`, `1<=N<=8`, canonical residues in `F_998244353`
- Valid / parseable frame: 18 / 19 signed-i64 words
- Domain: reject `b0=0`, any zero `C_n`, and any zero pre-inversion `D_n` divisor
- Output: `[N+1,h0,...,hN]`, maximum 80 bytes
- Native workspace: 128 bytes
- References: `primary_oracle.py`, `independent_oracle.py`
- Workload: `workload.json`
- Static helpers: `verify_workload.py`, `check_inventory.py`
- Sources: DLMF §3.10(iii), Lentz (1976), Thompson–Barnett (1986), Appendix III

All ten native paths appear in `INVENTORY.json`. The finite-field bounded
profile makes no convergence claim for an infinite continued fraction. No
helper or executable has been run.
