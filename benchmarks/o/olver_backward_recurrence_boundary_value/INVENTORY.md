# Package inventory

Algorithm: `olver_backward_recurrence_boundary_value`  
ABI: `float64_slice_io`  
Source: NIST DLMF §3.6(v), Eqs. 3.6.8–3.6.10.  
Input: `[M,Nmax,epsilon,w0,a...,b...,c...,d...]`, with `1<=M<=8` and
`M<=Nmax<=12`.  
Output: `[N,w0,...,wM]`; max 10 binary64 elements.  
Maximum valid/parseable input lengths: 52/53 binary64 elements.  
Caller output workspace: 10 elements / 80 bytes. Native primary scratch: 320
bytes.

## Native ports

- `c/o/olver_backward_recurrence_boundary_value.c`
- `c3/o/olver_backward_recurrence_boundary_value.c3`
- `cpp/o/olver_backward_recurrence_boundary_value.cpp`
- `elisa/o/olver_backward_recurrence_boundary_value.elisa`
- `mojo/o/olver_backward_recurrence_boundary_value.mojo`
- `nim/o/olver_backward_recurrence_boundary_value.nim`
- `odin/o/olver_backward_recurrence_boundary_value.odin`
- `rust/o/olver_backward_recurrence_boundary_value.rs`
- `v/o/olver_backward_recurrence_boundary_value.v`
- `zig/o/olver_backward_recurrence_boundary_value.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `__init__.py`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`

The nearby `miller_backward_recurrence_normalization` package uses a
homogeneous trial-tail recurrence and normalization functional. This profile
uses Olver's inhomogeneous forward error state and adaptive finite endpoint.
Only DLMF equations are used as mathematical source; no code or examples were
reused.
