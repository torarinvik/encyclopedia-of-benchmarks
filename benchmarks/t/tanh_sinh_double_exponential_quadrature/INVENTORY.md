# Package inventory

Algorithm: `tanh_sinh_double_exponential_quadrature`  
ABI: `float64_slice_io`  
Input: `[function_id,p]`; callback ID 0..3 and `p=2..4`.  
Method: Takahasi–Mori transform with `h=2^-p`, `K=3·2^p`, and the inclusive finite sum `j=-K..K`.  
Maximum valid / parseable input lengths: 2 / 3 words.  
Output: one float64 / 8 bytes; success 1, malformed -1, output error -2.  
Comparison tolerance: absolute `1e-5`, relative `1e-12`.  
Workspace metadata: one caller output element / 8 bytes; primary internal scratch O(1).

## Native ports

- `c/t/tanh_sinh_double_exponential_quadrature.c`
- `c3/t/tanh_sinh_double_exponential_quadrature.c3`
- `cpp/t/tanh_sinh_double_exponential_quadrature.cpp`
- `elisa/t/tanh_sinh_double_exponential_quadrature.elisa`
- `mojo/t/tanh_sinh_double_exponential_quadrature.mojo`
- `nim/t/tanh_sinh_double_exponential_quadrature.nim`
- `odin/t/tanh_sinh_double_exponential_quadrature.odin`
- `rust/t/tanh_sinh_double_exponential_quadrature.rs`
- `v/t/tanh_sinh_double_exponential_quadrature.v`
- `zig/t/tanh_sinh_double_exponential_quadrature.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`, `primary_oracle.py`, `independent_oracle.py`, `__init__.py`
- `verify_workload.py`, `check_inventory.py`

Primary source: Takahasi–Mori, [DOI 10.2977/PRIMS/1195192451](https://doi.org/10.2977/prims/1195192451). Independent oracle: exact integrals for four fixed functions. Discovery index: pinned RosettaCodeData popular-task revision `1d475861d7141ef2fafff293d9339f56e4b0f5db`.
