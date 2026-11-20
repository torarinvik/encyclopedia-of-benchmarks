# Package inventory

Algorithm: `stieltjes_quotient_difference_transform`  
ABI: `i64_array_bytes_output`  
Field: `F_998244353`  
Input: `[N,c0,...,c_(N-1)]`, `N=2..9`, canonical nonzero residues  
Output: `[N,a0,...,a_(N-1)]`, little-endian i64 words, at most 80 bytes  
Workspace: 720 bytes for fixed `q` and `e` tables  
Primary: Q-D rhombus recurrence  
Independent: Hankel-minor determinant ratios  
Source: NIST DLMF §3.10(ii), Eqs. 3.10.8–3.10.10

## Files

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`, `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`
- `c/s/stieltjes_quotient_difference_transform.c`
- `c3/s/stieltjes_quotient_difference_transform.c3`
- `cpp/s/stieltjes_quotient_difference_transform.cpp`
- `elisa/s/stieltjes_quotient_difference_transform.elisa`
- `mojo/s/stieltjes_quotient_difference_transform.mojo`
- `nim/s/stieltjes_quotient_difference_transform.nim`
- `odin/s/stieltjes_quotient_difference_transform.odin`
- `rust/s/stieltjes_quotient_difference_transform.rs`
- `v/s/stieltjes_quotient_difference_transform.v`
- `zig/s/stieltjes_quotient_difference_transform.zig`

Shared suite and catalog integration are root-owned.
