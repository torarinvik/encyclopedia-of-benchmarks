# TSVC s2710 nested scalar/vector branch update

This package profiles ControlFlow s2710. Each pass visits positions in ascending order. If `A[i] > B[i]`, it updates A by `B[i]*D[i]` and accumulates `D[i]^2` into C. Otherwise it assigns `B[i]=A[i]+E[i]^2`, then uses scalar x to either assign `C[i]=A[i]+D[i]^2` (x positive) or accumulate `E[i]^2` into C.

## Contract

The exported symbol is `tsvc_s2710_nested_scalar_vector_branch_update`, using `float64_slice_io`.

- Input is `[n,passes,x,A[n],B[n],C[n],D[n],E[n]]`; `11 <= n <= 64`, `1 <= passes <= 8`, and length is exactly `3+5*n`.
- x and all array values are finite integer-valued binary64 values in `[-1,1]`.
- Because n is at least 11, the source's `LEN > 10` test selects its `C[i] += D[i]*D[i]` arm for the `A[i] > B[i]` branch. The scalar `x > 0` split is retained in the other branch.
- Return final A, B, and C in that order; count `3*n`. D and E are unchanged, and input is not modified.
- Invalid input returns `-1`. Null output or capacity below `3*n` returns `-2` without writes.

The bounded integer-valued domain keeps all source-ordered updates exact in both TSVC float and double variants; outputs remain within `[-512,512]`. The pinned initializer sets A/B to one and C/D/E to reciprocal values. The ABI makes those arrays explicit so workloads can exercise both branch outcomes. Timing and the source's `ntimes/2` repetition count are outside this bounded profile.

This is distinct from s278/s279: s2710 compares A against B, mutates a different set of arrays in each branch, and has a separate scalar-controlled C update. s2711 remains a related but nonidentical AXPY predicate sibling of s271 (`B != 0` vs `B > 0`) and is not covered by this package.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, s2710 lines 2991–3026 and its initializer lines 525–530; selected by `TSVC/ControlFlow-dbl/info.sh` and `TSVC/ControlFlow-flt/info.sh`. The codelet accepts scalar x; the package exposes that scalar explicitly. The source comments attribute TSVC codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in the reviewed pinned materials. These are clean-room ports; see `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s2710_nested_scalar_vector_branch_update_oracle.py`](../../tsvc_s2710_nested_scalar_vector_branch_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2710_nested_scalar_vector_branch_update.c`](../../../c/t/tsvc_s2710_nested_scalar_vector_branch_update.c) |
| C3 | [`tsvc_s2710_nested_scalar_vector_branch_update.c3`](../../../c3/t/tsvc_s2710_nested_scalar_vector_branch_update.c3) |
| C++ | [`tsvc_s2710_nested_scalar_vector_branch_update.cpp`](../../../cpp/t/tsvc_s2710_nested_scalar_vector_branch_update.cpp) |
| Elisa | [`tsvc_s2710_nested_scalar_vector_branch_update.elisa`](../../../elisa/t/tsvc_s2710_nested_scalar_vector_branch_update.elisa) |
| Nim | [`tsvc_s2710_nested_scalar_vector_branch_update.nim`](../../../nim/t/tsvc_s2710_nested_scalar_vector_branch_update.nim) |
| Odin | [`tsvc_s2710_nested_scalar_vector_branch_update.odin`](../../../odin/t/tsvc_s2710_nested_scalar_vector_branch_update.odin) |
| Rust | [`tsvc_s2710_nested_scalar_vector_branch_update.rs`](../../../rust/t/tsvc_s2710_nested_scalar_vector_branch_update.rs) |
| V | [`tsvc_s2710_nested_scalar_vector_branch_update.v`](../../../v/t/tsvc_s2710_nested_scalar_vector_branch_update.v) |
| Zig | [`tsvc_s2710_nested_scalar_vector_branch_update.zig`](../../../zig/t/tsvc_s2710_nested_scalar_vector_branch_update.zig) |
