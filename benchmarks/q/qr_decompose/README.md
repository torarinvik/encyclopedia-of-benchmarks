# QR decomposition with classical Gram–Schmidt

This package implements the pinned `qr_decompose` operation: a column-wise classical Gram–Schmidt factorization of a small square matrix. It returns separate `Q` and `R` matrices. It is distinct from the `qr_decomposition` candidate, whose Python implementation uses Householder reflections.

## Contract

The `float64_slice_io` input is `[dimension, A_row_major...]`. The dimension is an exact integer in `1..4`; the matrix is square, row-major, and contains exact integer values in `[-4,4]`. Singular matrices are outside the supported domain and return `-1`; the bounded integer wrapper can reject them using an exact determinant check before calling the decomposition.

Process columns in increasing order. For column `i`, copy `A[:,i]` to both the source column and residual. For each earlier column `j`, project the original `A[:,i]` onto `Q[:,j]` as `(dot(A[:,i],Q[:,j])/dot(Q[:,j],Q[:,j]))*Q[:,j]`, then subtract that projection from the residual. Normalize the resulting residual to form `Q[:,i]`. Set `R[i,k] = dot(Q[:,i],A[:,k])` for `k >= i`, and set entries below the diagonal to zero. The bounded full-rank integer domain keeps all residual magnitudes finite and nonzero; the C source checks projection denominators for exact zero, while C++ checks against machine epsilon. Each projection denominator is the squared norm of a normalized prior Q column, so both guards take the normal projection path on this domain.

The output is the row-major `Q` matrix followed by the row-major `R` matrix. For every accepted input, `A ≈ Q*R`, `Qᵀ*Q ≈ I`, and `R` is upper triangular. Output comparisons use absolute and relative tolerances of `1e-12`. Malformed framing, unsupported bounds, fractional entries, singular matrices, or nonfinite results return `-1` before output checks. A null output buffer or capacity below `2*dimension*dimension` returns `-2` without writes.

The maximum valid input length is 17 values; one extra value is parseable so trailing data can be rejected. The maximum output length is 32 values.

## Pinned sources

- C [`qr_decompose.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/qr_decompose.h), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`, symbol `qr_decompose`.
- C++ [`qr_decompose.h`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/qr_decompose.h), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`, symbol `qr_algorithm::qr_decompose`.
- C++-1 [`qr_decompose.h`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/qr_decompose.h), commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`qr_decompose_oracle.py`](../../qr_decompose_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/q/qr_decompose.c`](../../../c/q/qr_decompose.c) |
| C3 | [`c3/q/qr_decompose.c3`](../../../c3/q/qr_decompose.c3) |
| C++ | [`cpp/q/qr_decompose.cpp`](../../../cpp/q/qr_decompose.cpp) |
| Elisa | [`elisa/q/qr_decompose.elisa`](../../../elisa/q/qr_decompose.elisa) |
| Nim | [`nim/q/qr_decompose.nim`](../../../nim/q/qr_decompose.nim) |
| Odin | [`odin/q/qr_decompose.odin`](../../../odin/q/qr_decompose.odin) |
| Rust | [`rust/q/qr_decompose.rs`](../../../rust/q/qr_decompose.rs) |
| V | [`v/q/qr_decompose.v`](../../../v/q/qr_decompose.v) |
| Zig | [`zig/q/qr_decompose.zig`](../../../zig/q/qr_decompose.zig) |
