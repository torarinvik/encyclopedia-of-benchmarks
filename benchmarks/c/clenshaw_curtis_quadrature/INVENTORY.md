# Package inventory

Algorithm: `clenshaw_curtis_quadrature`  
ABI: `float64_slice_io`  
Input: `[n,f0,...,fn]`, even `n` from 2 through 16, descending Chebyshev–Lobatto node order, finite samples bounded by 1000.  
Output: one binary64 integral estimate for the interpolant over `[-1,1]`.  
Maximum valid / parseable input lengths: 18 / 19 words.  
Output bound: one element / 8 bytes.  
Comparison tolerance: absolute `1e-9`, relative `1e-12`.  
Workspace metadata: one output element / 8 bytes; primary internal scratch O(1).

## Native ports

- `c/c/clenshaw_curtis_quadrature.c`
- `c3/c/clenshaw_curtis_quadrature.c3`
- `cpp/c/clenshaw_curtis_quadrature.cpp`
- `elisa/c/clenshaw_curtis_quadrature.elisa`
- `mojo/c/clenshaw_curtis_quadrature.mojo`
- `nim/c/clenshaw_curtis_quadrature.nim`
- `odin/c/clenshaw_curtis_quadrature.odin`
- `rust/c/clenshaw_curtis_quadrature.rs`
- `v/c/clenshaw_curtis_quadrature.v`
- `zig/c/clenshaw_curtis_quadrature.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

Suite integration: `benchmarks/run_float64_slice_io.py` and
`benchmarks/verify_float64_slice_io.py`.

Primary source: [DLMF Eq. 3.5.16](https://dlmf.nist.gov/3.5.E16). Independent identities: [DLMF Eq. 3.11.9](https://dlmf.nist.gov/3.11.E9) and [Eq. 3.11.11](https://dlmf.nist.gov/3.11.E11). Existing quadrature packages use distinct rules or adaptive procedures; Chebyshev polynomial evaluation is not quadrature.
