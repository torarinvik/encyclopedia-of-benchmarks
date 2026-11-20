# Static inventory

Algorithm: direct_discrete_fourier_transform  
ABI: float64_slice_io  
Entrypoint: direct_discrete_fourier_transform

The primary method is the direct O(N²) DFT sum for every N from 1 through 64. The independent method is complex Horner evaluation at roots of unity. Maximum valid input: 129 float64 values. Maximum parseable input: 130 values. Maximum output: 128 float64 values. Internal algorithm workspace: zero elements; scalar temporaries are used per output component. Tolerance: absolute 1e-9, relative 1e-12.

| Language | Source |
|---|---|
| C | c/d/direct_discrete_fourier_transform.c |
| C3 | c3/d/direct_discrete_fourier_transform.c3 |
| C++ | cpp/d/direct_discrete_fourier_transform.cpp |
| Elisa | elisa/d/direct_discrete_fourier_transform.elisa |
| Mojo | mojo/d/direct_discrete_fourier_transform.mojo |
| Nim | nim/d/direct_discrete_fourier_transform.nim |
| Odin | odin/d/direct_discrete_fourier_transform.odin |
| Rust | rust/d/direct_discrete_fourier_transform.rs |
| V | v/d/direct_discrete_fourier_transform.v |
| Zig | zig/d/direct_discrete_fourier_transform.zig |

Package-local static metadata: README.md, RIGHTS.md, workload.json, primary_oracle.py, independent_oracle.py, verify_workload.py, and check_inventory.py.

