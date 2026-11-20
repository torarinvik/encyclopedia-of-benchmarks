# Package inventory

Algorithm: `pade_approximant_series_coefficients`  
ABI: `i64_array_bytes_output`  
Source: NIST DLMF §3.11(iv), Eqs. 3.11.20–3.11.23.  
Field: `F_998244353`.  
Input: `[p,q,c0,...,c_(p+q)]`, `1<=q<=p<=4`, canonical residues.  
Output: `[p,q,a0,...,ap,b0,...,bq]`, with `b0=1`.  
Maximum valid / parseable input lengths: 11 / 12 words.  
Maximum output: 12 words / 96 bytes.  
Native scratch cap: 256 bytes.

## Native ports

- `c/p/pade_approximant_series_coefficients.c`
- `c3/p/pade_approximant_series_coefficients.c3`
- `cpp/p/pade_approximant_series_coefficients.cpp`
- `elisa/p/pade_approximant_series_coefficients.elisa`
- `mojo/p/pade_approximant_series_coefficients.mojo`
- `nim/p/pade_approximant_series_coefficients.nim`
- `odin/p/pade_approximant_series_coefficients.odin`
- `rust/p/pade_approximant_series_coefficients.rs`
- `v/p/pade_approximant_series_coefficients.v`
- `zig/p/pade_approximant_series_coefficients.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`

The rational-neighbor `rational_approximation` and point-based
`thiele_rational_interpolation` packages solve different operations. The
Padé profile matches a supplied formal-series prefix and emits normalized
numerator/denominator coefficients. Source: [NIST DLMF §3.11(iv)](https://dlmf.nist.gov/3.11.iv).
